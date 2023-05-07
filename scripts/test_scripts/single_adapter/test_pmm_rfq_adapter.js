const { ethers } = require("hardhat");
const { expect } = require("chai");
const { buildOrderRFQ, signOrderRFQ, makingAmount, takingAmount, unwrapWeth } = require('../../helpers/orderUtils');
require("../../tools");

async function deployContract() {
    await setForkBlockNumber(17128962);

    chainId = (await ethers.provider.getNetwork()).chainId;
    [onwer, taker, maker] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory('MockERC20');
    usdt = await MockERC20.deploy('USDT', 'USDT', 1000000000);
    await usdt.deployed();

    const WETH9 = await ethers.getContractFactory('WETH9');
    weth = await WETH9.deploy();
    await weth.deployed();

    const PMMProtocol = await ethers.getContractFactory('PMMProtocol');
    pmmProtocol = await upgrades.deployProxy(PMMProtocol, [weth.address]);
    await pmmProtocol.deployed();

    pmmProtocolAddr = pmmProtocol.address;
    //pmmProtocolAddr = "0x1111111254eeb25477b68fb85ed929f73a960582"; //1inch V5

    const PmmRFQAdapter = await ethers.getContractFactory("PmmRFQAdapter");
    pmmRFQAdapter = await PmmRFQAdapter.deploy(pmmProtocolAddr);
    await pmmRFQAdapter.deployed();
}

async function execute() {
    await weth.connect(maker).deposit({ value: '10' });
    await usdt.mint(taker.address, '1000000');

    await weth.connect(maker).approve(pmmProtocolAddr, '1');
    await usdt.connect(taker).approve(pmmProtocolAddr, '1900');

    await weth.connect(maker).approve(pmmRFQAdapter.address, '1');
    await usdt.connect(taker).approve(pmmRFQAdapter.address, '1900');

    const order = buildOrderRFQ(
        '0xFF000000000000000000000001',
        weth.address,
        usdt.address,
        maker.address,
        1,
        1900
    );
    const signature = await signOrderRFQ(order, chainId, pmmProtocolAddr, maker);

    //await pmmProtocol.connect(taker).fillOrderRFQ(order, signature, unwrapWeth(takingAmount(1900)));
    //await pmmProtocol.connect(taker).fillOrderRFQ(order, signature, unwrapWeth(makingAmount(1)));

    moreinfo = ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint256, address, address, address, address, uint256, uint256)", "bytes", "uint256"],
        [
            [
                "0xFF000000000000000000000001",
                weth.address,
                usdt.address,
                maker.address,
                "0x0000000000000000000000000000000000000000",
                "1",
                "1900",
            ],
            signature,
            unwrapWeth(takingAmount(1900))
        ]
    )
    const takerUSDT = await usdt.balanceOf(taker.address);
    await usdt.connect(taker).transfer(pmmRFQAdapter.address, '1900');

    const makerWETH = await weth.balanceOf(maker.address);
    const makerUSDT = await usdt.balanceOf(maker.address);
    const takerETH = await taker.getBalance();

    const rxResult = await pmmRFQAdapter.connect(taker).sellBase(
        taker.address,
        pmmProtocolAddr,
        moreinfo);
    const gasCost = await getTransactionCost(rxResult);
    console.log("gasCost: ", gasCost);

    const makerWETHAfter = await weth.balanceOf(maker.address);
    const makerUSDTAfter = await usdt.balanceOf(maker.address);
    const takerETHAfter = await taker.getBalance();
    const takerUSDTAfter = await usdt.balanceOf(taker.address);

    console.log("Maker WETH beforeBalance: ", makerWETH.toString());
    console.log("Maker USDT beforeBalance: ", makerUSDT.toString());
    console.log("Taker ETH beforeBalance: ", takerETH.toString());
    console.log("Taker USDT beforeBalance: ", takerUSDT.toString());
    console.log("\n");
    console.log("Maker WETH afterBalance: ", makerWETHAfter.toString());
    console.log("Maker USDT afterBalance: ", makerUSDTAfter.toString());
    console.log("Taker ETH afterBalance: ", takerETHAfter.toString());
    console.log("Taker USDT afterBalance: ", takerUSDTAfter.toString());

    expect(makerWETHAfter).to.equal(makerWETH.sub(1));
    expect(takerETHAfter).to.equal(takerETH.sub(gasCost).add(1));
    expect(makerUSDTAfter).to.equal(makerUSDT.add(1900));
    expect(takerUSDTAfter).to.equal(takerUSDT.sub(1900));
}

const getTransactionCost = async (txResult) => {
    const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
    return ethers.BigNumber.from(txResult.gasPrice).mul(ethers.BigNumber.from(cumulativeGasUsed));
};

async function main() {
    console.log("===== PmmRFQAdapter start =====");
    await deployContract();
    await execute();
    console.log("===== PmmRFQAdapter end =====");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
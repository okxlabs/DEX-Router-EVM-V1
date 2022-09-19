const { expect } = require("chai");
const { ethers } = require("hardhat");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER } = require("./utils");
require("../../tools");

async function deployContract() {
    SmoothyAdapter = await ethers.getContractFactory("SmoothyV1Adapter");
    SmoothyAdapter = await SmoothyAdapter.deploy();
    await SmoothyAdapter.deployed();
    return SmoothyAdapter
}

async function execute(network, blockNumber, userAddress) {
    await setForkNetWorkAndBlockNumber(network, blockNumber);
    await startMockAccount([userAddress]);
    // set account balance 100 eth
    await setBalance(userAddress, ethers.utils.parseEther("100"));
    
    const account = await ethers.getSigner(userAddress);

    const tokenConfig = getConfig("eth");

    // BUSD
    const BUSD = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BUSD.baseTokenAddress
    )
    
    // USDT
    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    SmoothyAdapter = await deployContract();

    let fromTokenAmount = ethers.utils.parseUnits("100", tokenConfig.tokens.USDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = ethers.constants.AddressZero;
    expect(await USDT.balanceOf(SmoothyAdapter.address)).to.be.equal(0);

    let mixAdapter1 = [
        SmoothyAdapter.address
    ];
    let assertTo1 = [
        SmoothyAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.BUSD.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256", "uint256"],
        [
            USDT.address,
            BUSD.address,
            0,
            5
        ]
    )
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,USDT.address];

    // layer1
    const layer1 = [router1];

    console.log("before Account BUSD Balance: " + await BUSD.balanceOf(account.address) / 10**tokenConfig.tokens.BUSD.decimals);
    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address) / 10**tokenConfig.tokens.USDT.decimals);

    let baseRequest = [
        USDT.address,
        BUSD.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        []
    );

    console.log("after Account USDT Balance: " + await USDT.balanceOf(account.address) / 10**tokenConfig.tokens.USDT.decimals);
    console.log("after Account BUSD Balance: " + await BUSD.balanceOf(account.address) / 10**tokenConfig.tokens.BUSD.decimals);
    expect(await BUSD.balanceOf(account.address) / 1e18).to.be.equal(99.96)
}

async function main() {
    // Banance 8 Address
    userAddress = "0xF977814e90dA44bFA03b6295A0616a897441aceC"
    // OKX 7
    userAddress = "0x5041ed759dd4afc3a72b8192c143f72f4724081a"
    await execute(
        "eth",
        15500417,
        userAddress,
    );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







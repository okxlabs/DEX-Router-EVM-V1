const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const factory = "0xa5eBD82503c72299073657957F41b9cEA6c0A43A"
    MaverickAdapter = await ethers.getContractFactory("MaverickAdapter");
    MaverickAdapter = await MaverickAdapter.deploy(factory, WETH);
    await MaverickAdapter.deployed();
    return MaverickAdapter
}

async function deployContract_Zk() {
    const WETH = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91"
    const factory = "0x96707414DB71e553F6a49c7aDc376e40F3BEfC33"
    MaverickAdapter = await ethers.getContractFactory("MaverickAdapter");
    MaverickAdapter = await MaverickAdapter.deploy(factory, WETH);
    await MaverickAdapter.deployed();
    return MaverickAdapter
}

//https://openchain.xyz/trace/ethereum/0x85c09e2a62a62a0a1d80dfd1c0885339598986bcf041758d83fe012eee3c3b96

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17162655 - 1);

    const MaverickAdapter = await deployContract();

    const accountSource = "0xB8d4E40051Ee565b9cECA299510bFd2b3676b028"
    const accountAddr = "0x1000000000000000000000100000000000000000"
    const poolAddr = "0x496d3Fe47211521EcA1ffF521d1f8022b0287c9F"




    const WETH = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WETH.baseTokenAddress
    );

    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));



    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await WETH.connect(account).deposit({ value: ethers.BigNumber.from("10000000000000000") });


    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );

    await WETH.connect(account).transfer(
        MaverickAdapter.address,
        ethers.BigNumber.from("10000000000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["tuple(bytes, address, bool)"],
        [
            [
                ethers.utils.solidityPack(["address", "address", "address"], [WETH.address, poolAddr, USDC.address]),
                MaverickAdapter.address,
                false
            ]
        ]
    );
    console.log(MaverickAdapter.address)
    console.log(moreInfo);
    await MaverickAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
}

// https://explorer.zksync.io/tx/0xe499ee6cb0fcf880cd19be9f6be7a1b69ba8023b9267d97039f129d402aef2d2#overview

async function executeERC20ToERC20_Zk() {
    let tokenConfig = getConfig("zksync")

    await setForkNetWorkAndBlockNumber("zksync", 2788561 - 1);

    const MaverickAdapter = await deployContract_Zk();

    const accountSource = "0x49D0BDFae6c6565C8343b900Fc480ab06764BF8A"
    const accountAddr = "0x1000000000000000000000100000000000000000"
    const poolAddr = "0x0C7C09d465fBeB7aa432F59d261C0F16344367F4"

    const wethAddr = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91"




    const WETH = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WETH.baseTokenAddress
    );
    const ETH = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.ETH.baseTokenAddress
    );

    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));



    await startMockAccount([wethAddr])
    const account = await ethers.getSigner(accountAddr)

    await WETH.connect(wethAddr).deposit({ value: ethers.BigNumber.from("400000000000000022") });
    await WETH.connect(wethAddr).transfer(accountAddr, ethers.BigNumber.from("400000000000000022"));
    await ETH.connect(wethAddr).transfer(accountAddr, ethers.utils.parseEther("10"));

    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );

    await WETH.connect(account).transfer(
        MaverickAdapter.address,
        ethers.BigNumber.from("400000000000000022")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["tuple(bytes, address, bool)"],
        [
            [
                ethers.utils.solidityPack(["address", "address", "address"], [WETH.address, poolAddr, USDC.address]),
                MaverickAdapter.address,
                false
            ]
        ]
    );
    console.log(MaverickAdapter.address)
    console.log(moreInfo);
    await MaverickAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
}


async function main() {

    console.log("==== checking ERC20 to ERC20 ethereum ====== ")
    await executeERC20ToERC20();

    // console.log("==== checking ERC20 to ERC20 zksync ====== ")
    // await executeERC20ToERC20_Zk();




}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

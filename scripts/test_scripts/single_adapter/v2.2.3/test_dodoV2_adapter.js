const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("eth")

async function deployContract() {
    dodoSellHelper = "0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb"
    DODOV2Adapter = await ethers.getContractFactory("DODOV2Adapter");
    DODOV2Adapter = await DODOV2Adapter.deploy();
    await DODOV2Adapter.deployed();
    return DODOV2Adapter
}

// address baseToken
// 0x6b175474e89094c44da98b954eedeac495271d0f
// address quoteToken
// 0xdac17f958d2ee523a2206206994597c13d831ec7
// address creator
// 0x16cc37d06fe5061cd0023fb8d142abaabb396a2b
// address DSP
// 0x3058ef90929cb8180174d74c507176cca6835d73

async function sellBase (DODOV2Adapter) {
    userAddress = "0xda8A87b7027A6C235f88fe0Be9e34Afd439570b5"
    DPSPool = "0x3058EF90929cb8180174D74C507176ccA6835D73"
    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);
    
    // WETH
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )
    
    // USDC
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    daiBalance = await DAI.balanceOf(signer.address);
    usdtBalance = await USDT.balanceOf(signer.address);
    console.log("Before DAI Balance: ", daiBalance.toString());
    console.log("Before USDT Balance: ", usdtBalance.toString());

    await DAI.connect(signer).transfer(DPSPool, await DAI.balanceOf(signer.address));
    await DODOV2Adapter.sellBase(signer.address, DPSPool, "0x");

    daiBalance = await DAI.balanceOf(signer.address);
    usdtBalance = await USDT.balanceOf(signer.address);
    console.log("After DAI Balance: ", daiBalance.toString());
    console.log("After USDT Balance: ", usdtBalance.toString());
}

async function sellQuote (DODOV2Adapter) {
    userAddress = "0xda8A87b7027A6C235f88fe0Be9e34Afd439570b5"
    DPSPool = "0x3058EF90929cb8180174D74C507176ccA6835D73"
    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);
    
    // WETH
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )
    
    // USDC
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    daiBalance = await DAI.balanceOf(signer.address);
    usdtBalance = await USDT.balanceOf(signer.address);
    console.log("Before DAI Balance: ", daiBalance.toString());
    console.log("Before USDT Balance: ", usdtBalance.toString());

    await USDT.connect(signer).transfer(DPSPool, ethers.utils.parseUnits("10000", 6));
    await DODOV2Adapter.sellQuote(signer.address, DPSPool, "0x");

    daiBalance = await DAI.balanceOf(signer.address);
    usdtBalance = await USDT.balanceOf(signer.address);
    console.log("After DAI Balance: ", daiBalance.toString());
    console.log("After USDT Balance: ", usdtBalance.toString());
}

async function main() {  
    DODOV2Adapter = await deployContract()
    console.log("======= sellBaseTesting ====== ")
    await sellQuote(DODOV2Adapter);
    console.log("======= sellBaseTesting ====== ")
    await sellBase(DODOV2Adapter);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

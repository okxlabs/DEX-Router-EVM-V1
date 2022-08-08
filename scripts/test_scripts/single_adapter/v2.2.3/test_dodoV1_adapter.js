

const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
const tokenConfig = getConfig("eth")

async function deployContract() {
    dodoSellHelper = "0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb"
    DODOV1Adapter = await ethers.getContractFactory("DODOV1Adapter");
    DODOV1Adapter = await DODOV1Adapter.deploy(dodoSellHelper);
    await DODOV1Adapter.deployed();
    return DODOV1Adapter
}

// DODO V1: https://etherscan.io/address/0x75c23271661d9d143dcb617222bc4bec783eff34#readContract

async function sellBaseTesting (DODOV1Adapter) {
    userAddress = "0x1c11ba15939e1c16ec7ca1678df6160ea2063bc5"
    poolAddress = "0x75c23271661d9d143DCb617222BC4BEc783eff34"
    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);
    
    // WETH
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    
    // USDC
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    // transfer token
    await WETH.connect(signer).transfer(DODOV1Adapter.address, ethers.utils.parseEther("1000"));

    wethBalance = await WETH.balanceOf(DODOV1Adapter.address);
    usdcBalance = await USDC.balanceOf(DODOV1Adapter.address);
    console.log("Before WETH Balance: ", wethBalance.toString());
    console.log("Before USDC Balance: ", usdcBalance.toString());


    rxResult = await DODOV1Adapter.sellBase(DODOV1Adapter.address, poolAddress, "0x");

    wethBalance = await WETH.balanceOf(DODOV1Adapter.address);
    usdcBalance = await USDC.balanceOf(DODOV1Adapter.address);
    console.log("After WETH Balance: ", wethBalance.toString());
    console.log("After USDC Balance: ", usdcBalance.toString());
}

async function sellQuoteTesting (DODOV1Adapter) {
    userAddress = "0x1c11ba15939e1c16ec7ca1678df6160ea2063bc5"
    poolAddress = "0x75c23271661d9d143DCb617222BC4BEc783eff34"
    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);
    
    // WETH
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    
    // USDC
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )


    wethBalance = await WETH.balanceOf(userAddress);
    usdcBalance = await USDC.balanceOf(userAddress);
    console.log("Before WETH Balance: ", wethBalance.toString());
    console.log("Before USDC Balance: ", usdcBalance.toString());

    rxResult = await DODOV1Adapter.sellQuote(userAddress, poolAddress, "0x");

    wethBalance = await WETH.balanceOf(userAddress);
    usdcBalance = await USDC.balanceOf(userAddress);
    console.log("After WETH Balance: ", wethBalance.toString());
    console.log("After USDC Balance: ", usdcBalance.toString());

    // // Withdraw tokens Left
    // deployer = await ethers.getSigner();
    // console.log("deployer: ", deployer.address);
    // tokensLeft = await USDC.balanceOf(DODOV1Adapter.address);
    // console.log("before withdraw, USDC tokensLeft: ", tokensLeft.toString());
    // await DODOV1Adapter.connect(deployer).withdrawLeftToken(poolAddress);
    // tokensLeft = await USDC.balanceOf(DODOV1Adapter.address);
    // console.log("after withdraw, USDC tokensLeft: ", tokensLeft.toString());

}

async function main() {  
    DODOV1Adapter = await deployContract()
    console.log("======= sellBaseTesting ====== ")
    await sellBaseTesting(DODOV1Adapter);
    console.log("======= sellQuoteTesting ====== ")
    await sellQuoteTesting(DODOV1Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

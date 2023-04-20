const { expect } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth");
const { initDexRouter } = require("./utils");

async function executeNative() {
    await setForkNetWorkAndBlockNumber("eth", 16941030);

    const tokenConfig = getConfig("eth");
  
    const accountAddress = "0x6B44ba0a126a2A1a8aa6cD1AdeeD002e141Bcd44";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    console.log(`Before WETH Balance: ${await WETH.balanceOf(account.address) / 1e18}`);
    console.log(`Before ETH Balance: ${await ethers.provider.getBalance(account.address) / 1e18}`);   

    let { dexRouter, tokenApprove } = await initDexRouter();
    
    // WETH -> ETH
    await WETH.connect(account).approve(tokenApprove.address, ethers.constants.MaxUint256);
    const rawData = "0x" + "80000000000000000000000000000000" + "0000000000000001a055690d9db80000" 
    await dexRouter.connect(account).swapWrap(0, rawData);
    
    // exchange 30 WETH to 30 ETH
    console.log(`After WETH -> ETH Balance expect reduce 30 WETH: ${await WETH.balanceOf(account.address) / 1e18}`);     
    console.log(`After WETH -> ETH Balance expect increase 30 ETH: ${await ethers.provider.getBalance(account.address) / 1e18}`); 

    // ETH -> WETH
    const rawData1 = "0x" + "00000000000000000000000000000000" + "0000000000000001a055690d9db80000"
    await dexRouter.connect(account).swapWrap(1, rawData1, {value: ethers.BigNumber.from("0x1a055690d9db80000")});
    
    // exchange 30 ETH to 30 WETH
    console.log(`After ETH -> WETH Balance expect increase 30 WETH: ${await WETH.balanceOf(account.address) / 1e18}`);
    console.log(`After ETH -> WETH Balance expect reduce 30 WETH: ${await ethers.provider.getBalance(account.address) / 1e18}`); 
}

async function main() {
    await executeNative();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

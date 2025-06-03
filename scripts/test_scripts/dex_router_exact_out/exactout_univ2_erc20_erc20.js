const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

// https://basescan.org/tx/0x8e2c995bbf0f7df71cb18d05cb574792f3692e4cf63e2fccfbdcdd3cdff5c231
async function main() {
    const dexRouterExactOut = await ethers.getContractAt("DexRouterExactOut", "0x1a9696A8684C5870008b8b7ba7cFCee24Da0D667");
    console.log("DexRouterExactOut: " + dexRouterExactOut.address);
    const gasPrice = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPrice);

    // usdc -> dai
    const srcToken = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";  // usdc
    const pool = "0x950847d1dd451b67a2fc1795c0c9a53cf88e63a2"
    const amount = ethers.utils.parseUnits("0.1", 18);      // want 0.1 dai
    const maxConsume = ethers.utils.parseUnits("0.2", 6);   // max use 0.2usdc
    const receiver = "0x8B3997e0a91DDF63585aBbC032C406F47ad45633"
    const poolFee = Number(997000000).toString(16).replace('0x', '');
    const pool0 = "0x8" + '000000000000000' + poolFee + pool.replace('0x', '');

    const swapTx = await dexRouterExactOut.unxswapExactOutTo(
        srcToken,
        amount,
        maxConsume,
        receiver,
        [pool0],
        // {
        //     gasLimit: 800000n
        // }
    );
    await swapTx.wait();


}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});
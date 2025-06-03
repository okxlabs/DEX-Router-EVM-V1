const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

// https://basescan.org/tx/0xfdb5714ac25af9da15fe32b53e07805bee79f6ebe78feb62b715e3879763eda0
async function main() {
    const dexRouterExactOut = await ethers.getContractAt("DexRouterExactOut", "0x1a9696A8684C5870008b8b7ba7cFCee24Da0D667");
    console.log("DexRouterExactOut: " + dexRouterExactOut.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);

    // usdc -> dai
    const receiver = "0x8B3997e0a91DDF63585aBbC032C406F47ad45633";
    const amountOut = ethers.utils.parseUnits("0.1", 18);      // want 0.1 dai
    const maxConsume = ethers.utils.parseUnits("0.2", 6);   // max use 0.2usdc
    const pool = "0xc18f50d6a832f12f6dcaaeee8d0c87a65b96787e"
    const poolFee = Number(997000000).toString(16).replace('0x', '');
    const pool0 = "0x8" + '000000000000000' + poolFee + pool.replace('0x', '');

    const swapTx = await dexRouterExactOut.uniswapV3SwapExactOutTo(
        receiver,
        amountOut,
        maxConsume,
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
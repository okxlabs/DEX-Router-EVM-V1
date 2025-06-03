const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

// https://basescan.org/tx/0x40c566e2c7ce6c9a9283abcbe6d0a896ee7269e45062809fe603c6a1a5dfc707
async function main() {
    const dexRouterExactOut = await ethers.getContractAt("DexRouterExactOut", "0x1a9696A8684C5870008b8b7ba7cFCee24Da0D667");
    console.log("DexRouterExactOut: " + dexRouterExactOut.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);

    // eth -> usdc
    const srcToken = "0x0000000000000000000000000000000000000000";  // eth
    const pool = "0x88a43bbdf9d098eec7bceda4e2494615dfd9bb9c"
    const amount = ethers.utils.parseUnits("0.1", 6);      // want 0.1 usdc
    const maxConsume = ethers.utils.parseUnits("0.0001", 18);   // max use 0.0001 eth
    const receiver = "0x8B3997e0a91DDF63585aBbC032C406F47ad45633"
    const poolFee = Number(997000000).toString(16).replace('0x', '');
    const pool0 = "0x0" + '000000000000000' + poolFee + pool.replace('0x', '');

    const swapTx = await dexRouterExactOut.unxswapExactOutTo(
        srcToken,
        amount,
        maxConsume,
        receiver,
        [pool0],
        {
            value: maxConsume
            // gasLimit: 800000n
        }
    );
    await swapTx.wait();


}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});
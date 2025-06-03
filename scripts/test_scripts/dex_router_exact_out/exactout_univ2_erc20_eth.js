const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

//   https://basescan.org/tx/0x64b8465112f18058381f486e06b01c4d973adae87973552b5ebd96d813dd98d3
async function main() {
    const dexRouterExactOut = await ethers.getContractAt("DexRouterExactOut", "0x1a9696A8684C5870008b8b7ba7cFCee24Da0D667");
    console.log("DexRouterExactOut: " + dexRouterExactOut.address);
    const gasPrice = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPrice);

    // usdc -> eth
    const srcToken = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";  // usdc
    const pool = "0x88a43bbdf9d098eec7bceda4e2494615dfd9bb9c"
    const amount = ethers.utils.parseUnits("0.0001", 18);      // want 0.0001 eth
    const maxConsume = ethers.utils.parseUnits("0.3", 6);   // max use 0.3 usdc
    const receiver = "0x8B3997e0a91DDF63585aBbC032C406F47ad45633"
    const poolFee = Number(997000000).toString(16).replace('0x', '');
    const pool0 = "0xc" + '000000000000000' + poolFee + pool.replace('0x', '');

    const swapTx = await dexRouterExactOut.unxswapExactOutTo(
        srcToken,
        amount,
        maxConsume,
        receiver,
        [pool0],
        // {
        //     value: maxConsume
        //     // gasLimit: 800000n
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
const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

// https://basescan.org/tx/0xbed063ecafe56d3fa923b4855f5698753bfae44f6cf3508e44c886028789eeea
async function main() {
    const dexRouterExactOut = await ethers.getContractAt("DexRouterExactOut", "0x1a9696A8684C5870008b8b7ba7cFCee24Da0D667");
    console.log("DexRouterExactOut: " + dexRouterExactOut.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);

    // usdc -> eth
    const receiver = "0x8B3997e0a91DDF63585aBbC032C406F47ad45633"
    const amountOut = ethers.utils.parseUnits("0.0001", 18);      // want 0.0001 eth
    const maxConsume = ethers.utils.parseUnits("0.3", 6);   // max use 0.3 usdc
    const pool = "0x18b497f71122622557e4634c47a05647ff859f47"
    const poolFee = Number(997000000).toString(16).replace('0x', '');
    const pool0Base = BigInt("0x" + "c" + "000000000000000" + poolFee + pool.replace("0x", ""));
    const _WETH_UNWRAP_MASK = BigInt(1) << BigInt(253);
    const pool0 = pool0Base | _WETH_UNWRAP_MASK;

    const swapTx = await dexRouterExactOut.uniswapV3SwapExactOutTo(
        receiver,
        amountOut,
        maxConsume,
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
const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

//   https://basescan.org/tx/0x1817becb90f369e53332c79e390bac0ed2750d9edef3bffc45c4aca801ac278f
async function main() {
    const dexRouterExactOut = await ethers.getContractAt("DexRouterExactOut", "0x1a9696A8684C5870008b8b7ba7cFCee24Da0D667");
    console.log("DexRouterExactOut: " + dexRouterExactOut.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);

    // eth -> usdc
    const receiver = "0x8B3997e0a91DDF63585aBbC032C406F47ad45633";
    const amountOut = ethers.utils.parseUnits("0.1", 6);      // want 0.1 usdc
    const maxConsume = ethers.utils.parseUnits("0.0001", 18);   // max use 0.0001 eth
    const pool = "0x18b497f71122622557e4634c47a05647ff859f47"
    const poolFee = Number(997000000).toString(16).replace('0x', '');
    const pool0 = "0x0" + '000000000000000' + poolFee + pool.replace('0x', '');

    const swapTx = await dexRouterExactOut.uniswapV3SwapExactOutTo(
        receiver,
        amountOut,
        maxConsume,
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
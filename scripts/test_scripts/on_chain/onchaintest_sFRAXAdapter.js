const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    //trace: https://etherscan.io/tx/0x7d3137099bf7e3c9a2e73b02514777bbd7e9291fa09389ea8a23e5fd6cedbd23
    const dexRouter = await ethers.getContractAt("DexRouter", "0x3b3ae790Df4F312e745D270119c6052904FB6790");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0x414F6d5cf73a96dcBb0BFc6D1C567f3e8a382Dc0"
    let poolAddress = "0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32"; 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32"//sFRAX
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x853d955aCEf822Db058eb8505911ED77F175b99e"//frax
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.1", 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assertTo1 = [adapter];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")
    ];
    const moreInfo = "0x";
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    let pmmReq = []
    // await fromToken.approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
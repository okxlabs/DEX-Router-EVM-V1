const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPrice = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPrice);
    const adapter = "0x09a191DE731c61a9fcc1E9c6759a7355B61AA2A3"
    let pool = "0x3843C3FBdC1FdEA1971c0005A2627CAf5bB89e49"
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xA00744882684C3e4747faEFD68D283eA44099D03" //WIOTX
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xB01b6E19C4B26810c7bD98879C8854F7e0519507" //TREX
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.01", 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assetTo1 = [pool];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        pool.replace("0x", "")
    ];
    let moreInfo = "0x"
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assetTo1, rawData1, extraData1, fromToken.address];
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
    await fromToken.approve(tokenApprove.address, fromTokenAmount);
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
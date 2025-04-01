const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xE58b3089dF6667fBf99b75595a1671BaF6797D6d"
    let pool = "0x63eb7846642630456707c3efbb50a03c79b89d81"
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"//USDC
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x59d9356e565ab3a36dd77763fc0d87feaf85508c"//USDM
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.1", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assetTo1 = [adapter];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        pool.replace("0x", "")
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256", "uint256"],
        [
            fromToken.address,
            toToken.address,
            0,
            1
        ]
    )
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
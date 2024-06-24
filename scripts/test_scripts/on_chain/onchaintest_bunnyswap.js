const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0x127a986cE31AA2ea8E1a6a0F0D5b7E5dbaD7b0bE"
    let router = "0xBf250AE227De43deDaF01ccBFD8CC83027efc1E2"
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x4200000000000000000000000000000000000006"
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x0bD4887f7D41B35CD75DFF9FfeE2856106f86670"
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.0001", 18);
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
        router.replace("0x", "")
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256"],
        [
            fromTokenAmount,
            minReturnAmount,
        ]
    )
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
    //await fromToken.approve(tokenApprove.address, fromTokenAmount);
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
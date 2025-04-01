const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    //const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPrice = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPrice);
    const adapter = "0x13A325612168e9E9816c69E116C3E1A150273301"
    let pool = "0x8Ba209a81aa57691971d7eAee166bC249CfbbD90"
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x6C0bf4b53696b5434A0D21C7D13Aa3cbF754913E" //WEN
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x3B2bf2b523f54C4E454F08Aa286D03115aFF326c" //USDC
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.01", 18);
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
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    fromToken.address,
                    toToken.address,
                    2500
                ]
            )
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
    //await fromToken.approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq, {
            "gasLimit": 510972
        }
    );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
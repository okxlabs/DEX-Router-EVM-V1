const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x2E86f54943faFD2cB62958c3deed36C879e3E944");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x5fD2Dc91FF1dE7FF4AEB1CACeF8E9911bAAECa68");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xdB3af8dF1cab8ae4159ED6a9b33dF5f8C3aD1485"
    let poolAddress = "0x9BE8a40C9cf00fe33fd84EAeDaA5C4fe3f04CbC3"; 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x4300000000000000000000000000000000000003"//USDB
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x4300000000000000000000000000000000000004"//WETH
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.2", 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assertTo1 = [adapter];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        8 + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [
            fromToken.address,
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
        pmmReq, {
            "gasLimit": 563005
        }
    );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
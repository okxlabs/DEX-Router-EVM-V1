const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x127a986cE31AA2ea8E1a6a0F0D5b7E5dbaD7b0bE");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x8b773D83bc66Be128c60e07E17C8901f7a64F000");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xe0806b2027cc821F741792eE634ae42b2D519dB0"
    let poolAddress = "0xd5E29Fc407582d3972Bb4a99dcDBe9B684ab945e"; 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xe538905cf8410324e03A5A23C1c177a474D59b2b"//WOKB
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xf782E172A14Ee1c85cD980C15375bA0E87957028"//TCAT
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.001", 18);
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
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            fromToken.address,
            toToken.address,
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
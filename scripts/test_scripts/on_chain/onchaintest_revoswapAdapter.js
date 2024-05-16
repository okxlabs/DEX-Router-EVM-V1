const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x127a986cE31AA2ea8E1a6a0F0D5b7E5dbaD7b0bE");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x8b773D83bc66Be128c60e07E17C8901f7a64F000");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xf18F664bFc8F0AdAeB70f93063b192Cf58627988"
    let poolAddress = "0xF3b755FB1C3486c3878B1539c594B9e619a51995"; 
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xe538905cf8410324e03A5A23C1c177a474D59b2b"//WOKB
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x1e4a5963abfd975d8c9021ce480b42188849d41d"//USDT
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.1", 6);
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

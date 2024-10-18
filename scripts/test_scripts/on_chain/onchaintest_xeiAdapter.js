const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0xdB3af8dF1cab8ae4159ED6a9b33dF5f8C3aD1485");
    //const tokenApprove = await ethers.getContractAt("TokenApprove", "0x801D8ED849039007a7170830623180396492c7ED");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xEdBaB5dfAA165919Dfa94101c266e48c4e82D8Fd"
    let poolAddress = "0x9f1B5De11928Ce3efd8C837b793052Eec3D55161"; 
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7"//WSEI
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1"//USDC
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
            3000
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
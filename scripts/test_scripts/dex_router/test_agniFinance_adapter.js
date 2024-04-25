const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

//Tx record: https://explorer.mantle.xyz/tx/0xf966e9c0a1d28eb9cb025804c4c9ec59a4a49d3a6b83e1e582c8e500203f51f3?tab=index
async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0x62a7b6eb6A5d2DcAa05Bf53C7272afd9dA460a2c";
    let poolAddress = "0xD08C50F7E69e9aeb2867DefF4A8053d9A855e26A";  //WMNT--USDT

    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE"//USDT
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8"//WMNT
    )
    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }

    let fromTokenAmount = ethers.utils.parseEther('0.1');
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assertTo1 = [adapter];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        "0" + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")
    ];
    const data = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            fromToken.address,
            toToken.address
        ]
    )
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            data
        ]
    )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        ETH.address,
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
        pmmReq,
        {value: fromTokenAmount}
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});
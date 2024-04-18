const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

//Tx record: https://explorer.metis.io/tx/0xee4c182e234ee8530144eed0fadf2b14e484fcb06d9afa841e15b1def77dfcf5
async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xFA574f8B3152504E391E53FfF6e55E3Ee56e0889"
    let poolAddress = "0x5Ae3ee7fBB3Cb28C17e7ADc3a6Ae605ae2465091";  //ETH(token0)--USDC(token1)
    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xEA32A96608495e54156Ae48931A7c20f0dcc1a21"//USDC
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481"//WETH
    )

    let fromTokenAmount = ethers.utils.parseEther('0.01');
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
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint256"],
        [30]
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
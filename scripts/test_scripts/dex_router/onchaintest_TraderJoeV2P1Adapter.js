const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    //const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xfAd6a9eEe5b32E9B81bb217BaeF37742B2ca5B83"
    let poolAddress = "0x7ccD8a769d466340Fff36c6e10fFA8cf9077D988"; 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE"//USDT
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34"//USDe
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.1", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assertTo1 = [poolAddress];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")
    ];
    const moreInfo = "0x";
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
        pmmReq, {
            "gasLimit": 3109720901
        }
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});

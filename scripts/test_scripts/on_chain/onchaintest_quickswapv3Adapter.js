const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xfAd6a9eEe5b32E9B81bb217BaeF37742B2ca5B83"
    let poolAddress = "0x12CdDeD759B14bf6A34FbF6638aec9B735824a9E"; 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xb73603C5d87fA094B7314C74ACE2e64D165016fb"//
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x0Dc808adcE2099A9F62AA87D9670745AbA741746"//
    )
    let fromTokenAmount = ethers.utils.parseUnits("1", 6);
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
    let data =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            fromToken.address,
            toToken.address,
        ]
    )
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            data,
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
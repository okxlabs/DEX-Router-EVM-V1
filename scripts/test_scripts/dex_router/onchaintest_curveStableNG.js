const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

async function main() {
    //trace: https://www.okx.com/zh-hans/web3/explorer/eth/tx/0xb492cd305a3b78c17d2a753c95a3e214c0c52f91b83b0eb24405c2eede450859
    const dexRouter = await ethers.getContractAt("DexRouter", "0x3b3ae790Df4F312e745D270119c6052904FB6790");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xEcd7Eef15713997528896Cb5db7ec316Db4C2101"
    let poolAddress = "0x02950460E2b9529D0E00284A5fA2d7bDF3fA4d72"; 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"//USDC
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x4c9EDD5852cd905f086C759E8383e09bff1E68B3"//USDe
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
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            fromToken.address,
            toToken.address,
            1,
            0
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
    // await fromToken.approve(tokenApprove.address, fromTokenAmount);
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
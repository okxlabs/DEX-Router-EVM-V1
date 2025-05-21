const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x156ACd2bc5fC336D59BAAE602a2BD9b5e20D6672");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0x722db4f285F8bD91ef7AF6DA397e83f7fA4E80a7"
    let poolAddress = "0x7DBF07Ad92Ed4e26D5511b4F285508eBF174135D"; 
    USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
    fromToken = await ethers.getContractAt(
        "MockERC20",
        USDT//
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        USDC//
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
    const fromTokenBytes32 = ethers.utils.hexZeroPad(USDT, 32);
    const toTokenBytes32 = ethers.utils.hexZeroPad(USDC, 32);
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "bytes32"],
        [
            fromTokenBytes32,
            toTokenBytes32,
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
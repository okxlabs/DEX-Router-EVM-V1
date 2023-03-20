let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("arbitrum");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function deployAdapter() {
    TraderJoeV2Adapter = await ethers.getContractFactory("TraderJoeV2Adapter");
    TraderJoeV2Adapter = await TraderJoeV2Adapter.deploy();
    await TraderJoeV2Adapter.deployed();
    return TraderJoeV2Adapter
}

async function traderJoeUSDC2USDT(TraderJoeV2Adapter) {
    let pmmReq = []

    let accountAddress = "0x8b8149dd385955dc1ce77a4be7700ccd6a212e65";
    let poolAddress = "0x13FDa18516eAFe5e8AE930F86Fa51aE4B6C35E8F"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // WETH
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    // zyber token
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("200", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let is_underlying = false;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        TraderJoeV2Adapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let moreInfo = "0x";
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    
    await fromToken.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await toToken.balanceOf(account.address));

    console.log("token left: ", await toToken.balanceOf(TraderJoeV2Adapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function traderJoeUSDT2USDC(TraderJoeV2Adapter) {
    let pmmReq = []

    let accountAddress = "0x8b8149dd385955dc1ce77a4be7700ccd6a212e65";
    let poolAddress = "0x13FDa18516eAFe5e8AE930F86Fa51aE4B6C35E8F"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // WETH
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    // zyber token
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("200", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let is_underlying = false;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        TraderJoeV2Adapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let moreInfo = "0x";
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    
    await fromToken.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await toToken.balanceOf(account.address));

    console.log("token left: ", await toToken.balanceOf(TraderJoeV2Adapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function main() {
    TraderJoeV2Adapter = await deployAdapter();
    console.log("TraderJoeV2Adapter.address", TraderJoeV2Adapter.address);

    console.log(" =================== traderJoeUSDC2USDT ===================")
    await traderJoeUSDC2USDT(TraderJoeV2Adapter)

    console.log(" =================== traderJoeUSDT2USDC ===================")
    await traderJoeUSDT2USDC(TraderJoeV2Adapter)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







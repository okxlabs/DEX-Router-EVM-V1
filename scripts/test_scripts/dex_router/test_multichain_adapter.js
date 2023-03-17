let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function deployAdapter() {
    MultichainAdapter = await ethers.getContractFactory("MultichainAdapter");
    MultichainAdapter = await MultichainAdapter.deploy();
    await MultichainAdapter.deployed();
    return MultichainAdapter
}

// USDC <-> USDT
async function anyETHToWETH(MultichainAdapter) {
    let pmmReq = []

    let accountAddress = "0x2816686a73DAf4197DfFa39Dc741684bb7060a1B";
    let poolAddress = "0x0615Dbba33Fe61a31c7eD131BDA6655Ed76748B1"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x0615Dbba33Fe61a31c7eD131BDA6655Ed76748B1"
    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await fromToken.balanceOf(account.address);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    console.log("before Account fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " +  await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        MultichainAdapter.address
    ];
    let assertTo1 = [
        MultichainAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(toToken.address, fromToken.address) + 
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

}

async function main() {

    MultichainAdapter = await deployAdapter();
    console.log("MultichainAdapter.address", MultichainAdapter.address);
    
    console.log(" ============= Campletplot Stable Pool Shell Base  ===============");
    await anyETHToWETH(MultichainAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







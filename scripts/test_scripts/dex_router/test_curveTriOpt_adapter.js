let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
const { setForkBlockNumber } = require("../../tools/chain");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function executeCurveTriOpt1() {
    const pmmReq = []
    
    let poolAddress = "0x37417B2238AA52D0DD2D6252d989E728e8f706e4"; 
    let accountAddress = "0xa0456eaAE985BDB6381Bd7BAac0796448933f04f";
    // block 17718451
    await setForkBlockNumber(17718451);
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");
    
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xf939e0a03fb07f59a73314e73794be0e57ac1b4e"
    )

    console.log("before Account fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();

    CurveV2Adapter = await ethers.getContractFactory("CurveTriOptAdapter");
    CurveV2Adapter = await CurveV2Adapter.deploy();
    await CurveV2Adapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = "120928484214964005";
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    let mixAdapter1 = [
        CurveV2Adapter.address
    ];
    let assertTo1 = [
        CurveV2Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256", "uint256"],
        [
            fromToken.address,
            toToken.address,
            1,
            0
        ]
      )
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

    console.log("after Account fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await toToken.balanceOf(account.address));
}

async function executeCurveTriOpt2() {
    const pmmReq = []
    
    let poolAddress = "0x37417B2238AA52D0DD2D6252d989E728e8f706e4"; 
    let accountAddress = "0x3DCbCeE30665B3074C7c02D3031090815b3388f7";
    // block 17718451
    await setForkBlockNumber(17718451);
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");
    
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xf939e0a03fb07f59a73314e73794be0e57ac1b4e"

    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
    )

    console.log("before Account fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();

    CurveV2Adapter = await ethers.getContractFactory("CurveTriOptAdapter");
    CurveV2Adapter = await CurveV2Adapter.deploy();
    await CurveV2Adapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = await fromToken.balanceOf(account.address);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    let mixAdapter1 = [
        CurveV2Adapter.address
    ];
    let assertTo1 = [
        CurveV2Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256", "uint256"],
        [
            fromToken.address,
            toToken.address,
            0,
            1
        ]
      )
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

    console.log("after Account fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await toToken.balanceOf(account.address));
}

async function main() {
    console.log(" ============= Curve CurveTriOpt pool1: WSTETH => CRVUSD  ===============");
    await executeCurveTriOpt1();
    console.log(" ============= Curve CurveTriOpt pool2: WSTETH => CRVUSD  ===============");
    await executeCurveTriOpt2();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







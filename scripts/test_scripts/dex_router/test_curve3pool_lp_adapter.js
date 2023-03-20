let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("./utils")

pool_lp_token = "0x6c3f90f043a72fa612cbac8115ee7e52bde6e490"
async function deployAdapter() {
    Curve3poolLPAdapter = await ethers.getContractFactory("Curve3poolLPAdapter");
    Curve3poolLPAdapter = await Curve3poolLPAdapter.deploy(pool_lp_token);
    await Curve3poolLPAdapter.deployed();
    return Curve3poolLPAdapter
}

async function threeCrvToUSDT(CurveAdapter) {
    let pmmReq = []
    let poolAddress = "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7"; 
    let accountAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
      )

    // 3crv
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x6c3f90f043a72fa612cbac8115ee7e52bde6e490"
    )
    
    // 
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();


    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseEther("10000")
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        CurveAdapter.address
    ];
    let assertTo1 = [
        CurveAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(["int128"],[2])
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

async function usdtTo3crv(CurveAdapter) {
    let pmmReq = []
    let poolAddress = "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7"; 
    let accountAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
      )

    // 3crv
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )
    
    // 
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x6c3f90f043a72fa612cbac8115ee7e52bde6e490"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();


    // transfer ETH to curveAdapter
    let fromTokenAmount = await fromToken.balanceOf(account.address);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        CurveAdapter.address
    ];
    let assertTo1 = [
        CurveAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(["int128"],[2])
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

    CurveAdapter = await deployAdapter();
    console.log("CurveAdapter.address", CurveAdapter.address);

    console.log(" ============= threeCrvToUSDT ===============");
    await threeCrvToUSDT(CurveAdapter)

    console.log(" ============= usdtTo3crv ===============");
    await usdtTo3crv(CurveAdapter)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







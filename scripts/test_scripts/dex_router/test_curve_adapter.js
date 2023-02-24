let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function deployAdapter() {
    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await CurveAdapter.deployed();
    return CurveAdapter
}

async function executeCurveSETPool2(CurveAdapter) {
    let pmmReq = []

    let accountAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
      )

    // USDT
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
        )
    
    // stETH
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();


    // transfer ETH to curveAdapter
    let fromTokenAmount = await fromToken.balanceOf(accountAddress)
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0xDC24316b9AE028F1497c275EB9192a3Ea0f67022"; 

    console.log("before Account ETH Balance: " +  await ethers.provider.getBalance(account.address));
    console.log("before Account stETH Balance: " + await fromToken.balanceOf(account.address));

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
        direction(fromToken, tokenConfig.tokens.WETH.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128", "bool"],
        [
            fromToken.address,
            tokenConfig.tokens.ETH.baseTokenAddress,
            1,
            0,
            false
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
        tokenConfig.tokens.ETH.baseTokenAddress,
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

    console.log("before Account ETH Balance: " +  await ethers.provider.getBalance(account.address));
    console.log("after Account stETH Balance: " + await fromToken.balanceOf(account.address));

}

async function executeCurveSETPool(CurveAdapter) {
    let pmmReq = []

    let accountAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
      )

    // USDT
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
        )
    
    // stETH
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();


    // transfer ETH to curveAdapter
    let fromTokenAmount = ethers.utils.parseEther("1")
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0xDC24316b9AE028F1497c275EB9192a3Ea0f67022"; 

    console.log("before Account stETH Balance: " + await toToken.balanceOf(account.address));

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
        direction(tokenConfig.tokens.WETH.baseTokenAddress, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128", "bool"],
        [
            tokenConfig.tokens.ETH.baseTokenAddress,
            toToken.address,
            0,
            1,
            false
        ]
    )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        tokenConfig.tokens.ETH.baseTokenAddress,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {
            value: fromTokenAmount
        }
    );

    console.log("after Account stETH Balance: " + await toToken.balanceOf(account.address));

}

async function executeCurvePool(CurveAdapter) {
    let pmmReq = []

    let accountAddress = "0x99C2d01c89EA89839516B2758fBCa737FB939263";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    // USDT
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )
    
    // DAI
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();



    // transfer 6000 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("6000", tokenConfig.tokens.USDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"; 

    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));

    let mixAdapter1 = [
        CurveAdapter.address
    ];
    let assertTo1 = [
        CurveAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128", "bool"],
        [
            USDT.address,
            DAI.address,
            2,
            0,
            false
        ]
    )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1,USDT.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        USDT.address,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after CurveAdapter USDT Balance: " + await USDT.balanceOf(CurveAdapter.address));
    console.log("after Account DAI Balance: " + await DAI.balanceOf(account.address));
}

async function execute_underlying(CurveAdapter) {
    const pmmReq = [];

    // V神
    let accountAddress = "0x99C2d01c89EA89839516B2758fBCa737FB939263";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    // USDT
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    //WUST
    WUST = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WUST.baseTokenAddress
    )

    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("before Account WUST Balance: " + await WUST.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    // transfer 6000 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("500", tokenConfig.tokens.DAI.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x890f4e345b1daed0367a877a1612f86a1f86985f"; 

    let mixAdapter1 = [
        CurveAdapter.address
    ];
    let assertTo1 = [
        CurveAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.DAI.baseTokenAddress, tokenConfig.tokens.WUST.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128", "bool"],
        [
            DAI.address,
            WUST.address,
            1,
            0,
            true
        ]
      )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1,DAI.address];

    // layer1
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        DAI.address,
        WUST.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("after Account WUST Balance: " + await WUST.balanceOf(account.address));
}

async function main() {

    CurveAdapter = await deployAdapter();
    console.log("CurveAdapter.address", CurveAdapter.address);
    
    console.log(" ============= Curve 3pool pool ===============");
    await executeCurvePool(CurveAdapter);
    console.log(" ============= Curve meta pool ===============");
    await execute_underlying(CurveAdapter);
    console.log(" ============= Curve SETH pool ===============");
    await executeCurveSETPool(CurveAdapter)
    console.log(" ============= Curve SETH2 pool ===============");
    await executeCurveSETPool2(CurveAdapter)


}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
let { WUST } = require("../../config/eth/tokens");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function executeCurvePool() {
    await setForkBlockNumber(14436483);

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
    
    // DAI
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy();
    await CurveAdapter.deployed();

    // transfer 6000 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("6000", tokenConfig.tokens.USDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"; 

    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));

    // arguments
    let requestParam1 = [
        tokenConfig.tokens.USDT.baseTokenAddress,
        [fromTokenAmount]
    ];
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
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1];
      
    //   // layer1
    let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        USDT.address,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [request1],
        [layer1],
    );

    console.log("after CurveAdapter USDT Balance: " + await USDT.balanceOf(CurveAdapter.address));
    console.log("after Account DAI Balance: " + await DAI.balanceOf(account.address));


}

async function execute_underlying() {
    await setForkBlockNumber(14436483);

    // V神
    let accountAddress = "0x1Db3439a222C519ab44bb1144fC28167b4Fa6EE6";
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

    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy();
    await CurveAdapter.deployed();

    // transfer 6000 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("500", tokenConfig.tokens.DAI.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x890f4e345b1daed0367a877a1612f86a1f86985f"; 

    // arguments
    let requestParam1 = [
        tokenConfig.tokens.DAI.baseTokenAddress,
        [fromTokenAmount]
    ];
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
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1];
      
    //   // layer1
    let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        DAI.address,
        WUST.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [request1],
        [layer1],
    );

    console.log("after Account DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("after Account WUST Balance: " + await WUST.balanceOf(account.address));
}


async function main() {
    console.log(" ============= Curve 3pool pool ===============");
    await executeCurvePool();
    console.log(" ============= Curve meta pool ===============");
    await execute_underlying();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







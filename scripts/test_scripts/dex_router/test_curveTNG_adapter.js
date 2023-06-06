let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function executeTricryptoNG() {
    const pmmReq = []
    
    let poolAddress = "0xf5f5B97624542D72A9E06f04804Bf81baA15e2B4"; 
    let accountAddress = "0x1Cb17a66DC606a52785f69F08F4256526aBd4943";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");
    
    // USDT
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WBTC.baseTokenAddress
    )

    // WETH
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    console.log("before Account fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();

    CurveV2Adapter = await ethers.getContractFactory("CurveTNGAdapter");
    CurveV2Adapter = await CurveV2Adapter.deploy();
    await CurveV2Adapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("0.5", tokenConfig.tokens.WBTC.decimals);
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


async function main() {
    console.log(" ============= Curve tricrypto pool ===============");
    await executeTricryptoNG();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







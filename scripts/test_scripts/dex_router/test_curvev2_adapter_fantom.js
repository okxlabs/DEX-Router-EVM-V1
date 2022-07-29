let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("ftm");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function executeTricrypto() {
    const pmmReq = []

    let accountAddress = "0x15d1bfe5f771ca0369d42fc0edf491f032332d3e";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    FUSDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.FUSDT.baseTokenAddress
    )

    // WETH
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    console.log("before Account FUSDT Balance: " + await FUSDT.balanceOf(account.address));
    console.log("before Account WETH Balance: " + await WETH.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();

    CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
    CurveV2Adapter = await CurveV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await CurveV2Adapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("500", tokenConfig.tokens.FUSDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x3a1659ddcf2339be3aea159ca010979fb49155ff"; 
    await FUSDT.connect(account).transfer(CurveV2Adapter.address, fromTokenAmount);
    console.log("before CurveV2Adapter FUSDT Balance: " + await FUSDT.balanceOf(CurveV2Adapter.address));

    let mixAdapter1 = [
        CurveV2Adapter.address
    ];
    let assertTo1 = [
        CurveV2Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.FUSDT.baseTokenAddress, tokenConfig.tokens.WETH.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            FUSDT.address,
            WETH.address,
            0,
            2
        ]
      )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1,FUSDT.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        FUSDT.address,
        WETH.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await FUSDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account USDT Balance: " + await FUSDT.balanceOf(account.address));
    console.log("after Account WETH Balance: " + await WETH.balanceOf(account.address));
}


async function main() {
    console.log(" ============= Curve tricrypto pool ===============");
    await executeTricrypto();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







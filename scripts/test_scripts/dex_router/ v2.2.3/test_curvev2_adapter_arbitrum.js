let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("arbitrum");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function executeTricrypto() {
    const pmmReq = []

    let accountAddress = "0xa97Bd3094fB9Bf8a666228bCEFfC0648358eE48F";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    // WETH
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before Account WETH Balance: " + await WETH.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();

    CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
    CurveV2Adapter = await CurveV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await CurveV2Adapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("500", tokenConfig.tokens.USDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x960ea3e3C7FB317332d990873d354E18d7645590"; 
    await USDT.connect(account).transfer(CurveV2Adapter.address, fromTokenAmount);
    console.log("before CurveV2Adapter USDT Balance: " + await USDT.balanceOf(CurveV2Adapter.address));

    let mixAdapter1 = [
        CurveV2Adapter.address
    ];
    let assertTo1 = [
        CurveV2Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.WETH.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            USDT.address,
            WETH.address,
            0,
            2
        ]
      )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1,USDT.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        USDT.address,
        WETH.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account USDT Balance: " + await USDT.balanceOf(account.address));
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







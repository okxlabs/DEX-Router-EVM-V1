const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER} = require("./utils")

async function executeUSDT2DAI() {
    const pmmReq = []
    await setForkBlockNumber(16668912);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));    
    
    let { dexRouter, tokenApprove } = await initDexRouter();
    
    NomiswapAdapter = await ethers.getContractFactory("NomiswapAdapter");
    nomiswapAdapter = await NomiswapAdapter.deploy("0xEfD2f571989619a942Dc3b5Af63866B57D1869ED", "0x818339b4E536E707f14980219037c5046b049dD4");
    await nomiswapAdapter.deployed();

    // transfer 5 USDT to nomiswapStablePool
    const fromTokenAmount = ethers.utils.parseUnits("5", tokenConfig.tokens.USDT.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x9Daeb0A1849D57f6BEBe0e5969644950f0689936";//DAI-USDT Pool
    //await USDT.connect(account).transfer(poolAddress, fromTokenAmount);
    //console.log("before CurveV2Adapter USDT Balance: " + await USDT.balanceOf(CurveV2Adapter.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];

    const mixAdapter1 = [
        nomiswapAdapter.address
    ];
    const assertTo1 = [
        poolAddress
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")  // DAI-USDT Pool
    ];
    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, USDT.address];

    // layer1
    // let request1 = [requestParam1];
    const layer1 = [router1];
    const orderId = 0;

    const baseRequest = [
        USDT.address,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    
    tx = await dexRouter.connect(account).smartSwapByOrderId(//dexrouter里面的函数
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    console.log(tx);
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
}



async function main() {
    // await executeNative();
    await executeUSDT2DAI();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

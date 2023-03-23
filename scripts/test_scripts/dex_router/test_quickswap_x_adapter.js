const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("polygon")
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")

async function executeWMATIC2USDC() {
    const pmmReq = []
    await setForkNetWorkAndBlockNumber('polygon',40528787);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WMATIC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WMATIC.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    console.log("before Account WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("before Account USDC Balance: " + await USDC.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(WMATIC.address);

    QuickswapAdapter = await ethers.getContractFactory("QuickswapAdapter");
    quickswapAdapter = await QuickswapAdapter.deploy();
    await quickswapAdapter.deployed();

    // transfer 1 WMATIC to quickswapPool
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.WMATIC.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827";//WMATIC-USDC  Pool


    // console.log("before WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    // console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WMATIC.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        quickswapAdapter.address
    ];
    const assertTo1 = [
        poolAddress
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        "0" +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")  // WMATIC-USDC Pool
    ];
    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WMATIC.address];

    // layer1
    const layer1 = [router1];
    const orderId = 0;

    const baseRequest = [
        WMATIC.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await WMATIC.connect(account).approve(tokenApprove.address, fromTokenAmount);
   
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    console.log(tx);
    console.log("after WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
}


//From and To Native
async function executeNative() {
    const pmmReq = []
    await setForkNetWorkAndBlockNumber('polygon',40586864);
    //https://polygonscan.com/tx/0x6c81f52743d1e8598d3d43a72c676ab8229f1acc7407fd4185bf16fb2611fe97
    //real tx in 40586865

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WMATIC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WMATIC.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter(WMATIC.address);

    QuickswapAdapter = await ethers.getContractFactory("QuickswapAdapter");
    quickswapAdapter = await QuickswapAdapter.deploy();
    await quickswapAdapter.deployed();


    // from native
    const orderId = 0;
    const fromTokenAmount = ethers.utils.parseEther('1');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827"; // WMATIC-USDC Pool

    let usdcBalance0 = await USDC.balanceOf(account.address);
    console.log("before MATIC Balance: " + await account.getBalance());
    console.log("before USDC Balance: " + usdcBalance0);

    // node1
    const mixAdapter1 = [
        quickswapAdapter.address
    ];
    const assertTo1 = [
        poolAddress
    ];
    const weight1 = 10000;
    const rawData1 = [packRawData(tokenConfig.tokens.WMATIC.baseTokenAddress,tokenConfig.tokens.USDC.baseTokenAddress,weight1,poolAddress)];

    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WMATIC.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        tokenConfig.tokens.MATIC.baseTokenAddress,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // await WMATIC.connect(account).approve(tokenApprove.address, fromTokenAmount);
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq, {value: fromTokenAmount}
    );

    let usdcBalance = await USDC.balanceOf(account.address);
    console.log("after MATIC  Balance: " + await account.getBalance());
    console.log("after USDC Balance: " + usdcBalance);

    let adapterBalance = await ethers.provider.getBalance(quickswapAdapter.address)
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance, 0,"adapter has matic left");
    assert.equal(dexRouterBalance, 0,"dexRouter has matic left");
    assert.equal(usdcBalance-usdcBalance0, 1107403,"USDC balance error");

    //to Native
    const orderId2 = 1;
    const fromTokenAmount2 = ethers.utils.parseUnits('1.107403', 6);
    const minReturnAmount2 = 0;

    console.log("before MATIC Balance: " + await account.getBalance());
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // node1
    const mixAdapter2 = [
        quickswapAdapter.address
    ];
    const assertTo2 = [
        poolAddress
    ];
    const weight2 = 10000;
    const rawData2 = [packRawData(tokenConfig.tokens.USDC.baseTokenAddress,tokenConfig.tokens.WMATIC.baseTokenAddress,weight2,poolAddress)];

    const moreInfo2 = "0x"
    const extraData2 = [moreInfo2];
    const router2 = [mixAdapter2, assertTo2, rawData2, extraData2, USDC.address];

    // layer1
    const layer2 = [router2];

    const baseRequest2 = [
        USDC.address,
        tokenConfig.tokens.MATIC.baseTokenAddress,
        fromTokenAmount2,
        minReturnAmount2,
        deadLine,
    ]

    await USDC.connect(account).approve(tokenApprove.address, fromTokenAmount2);
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId2,
        baseRequest2,
        [fromTokenAmount2],
        [layer2],
        pmmReq
    );

    let usdcBalance2 = await USDC.balanceOf(account.address)
    console.log("after MATIC Balance: " + await account.getBalance());
    console.log("after USDC Balance: " + usdcBalance2);

    let adapterBalance2 = await ethers.provider.getBalance(quickswapAdapter.address)
    let dexRouterBalance2 = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance2, 0,"adapter has matic left");
    assert.equal(dexRouterBalance2, 0,"dexRouter has matic left");
    assert.equal(usdcBalance2.toString(), usdcBalance0.toString(),"USDC balance error")

}

async function main() {
    await executeNative();
    //await executeWMATIC2USDC();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

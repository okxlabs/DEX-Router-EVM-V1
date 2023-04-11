const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("ftm")
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")

async function executeWFTM2DAI() {
    const pmmReq = []
    await setForkNetWorkAndBlockNumber('fantom',59053927);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WFTM = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WFTM.baseTokenAddress
    )
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    console.log("before Account WFTM Balance: " + await WFTM.balanceOf(account.address));
    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(WFTM.address);

    SpiritswapV2Adapter = await ethers.getContractFactory("SpiritswapV2Adapter");
    spiritswapV2Adapter = await SpiritswapV2Adapter.deploy();
    await spiritswapV2Adapter.deployed();

    // transfer 1 WFTM to quickswapPool
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.WFTM.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x1c8dd14e77C20eB712Dc30bBf687a282CFf904a2";//WFTM-DAI  Pool


    // console.log("before WFTM Balance: " + await WFTM.balanceOf(account.address));
    // console.log("before DAI Balance: " + await DAI.balanceOf(account.address));

    const mixAdapter1 = [
        spiritswapV2Adapter.address
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
        poolAddress.replace("0x", "")  // WFTM-DAI Pool
    ];
    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WFTM.address];

    // layer1
    const layer1 = [router1];
    const orderId = 0;

    const baseRequest = [
        WFTM.address,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await WFTM.connect(account).approve(tokenApprove.address, fromTokenAmount);
   
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    //console.log(tx);
    console.log("after WFTM Balance: " + await WFTM.balanceOf(account.address));
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
}

/*
//From and To Native
async function executeNative() {
    const pmmReq = []
    await setForkNetWorkAndBlockNumber('fantom',59053927);
    

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WFTM = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WFTM.baseTokenAddress
    )
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter(WFTM.address);

    SpiritswapV2Adapter = await ethers.getContractFactory("SpiritswapV2Adapter");
    spiritswapV2Adapter = await SpiritswapV2Adapter.deploy();
    await spiritswapV2Adapter.deployed();


    // from native
    const orderId = 0;
    const fromTokenAmount = ethers.utils.parseEther('1');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x1c8dd14e77C20eB712Dc30bBf687a282CFf904a2"; // WFTM-DAI Pool

    let daiBalance0 = await DAI.balanceOf(account.address);
    console.log("before FTM Balance: " + await account.getBalance());
    console.log("before DAI Balance: " + daiBalance0);

    // node1
    const mixAdapter1 = [
        spiritswapV2Adapter.address
    ];
    const assertTo1 = [
        poolAddress
    ];
    const weight1 = 10000;
    const rawData1 = [packRawData(tokenConfig.tokens.WFTM.baseTokenAddress,tokenConfig.tokens.DAI.baseTokenAddress,weight1,poolAddress)];

    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WFTM.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        tokenConfig.tokens.FTM.baseTokenAddress,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // await WFTM.connect(account).approve(tokenApprove.address, fromTokenAmount);
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq, {value: fromTokenAmount}
    );

    let daiBalance = await DAI.balanceOf(account.address);
    console.log("after FTM  Balance: " + await account.getBalance());
    console.log("after DAI Balance: " + daiBalance);

    let adapterBalance = await ethers.provider.getBalance(spiritswapV2Adapter.address)
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance, 0,"adapter has matic left");
    assert.equal(dexRouterBalance, 0,"dexRouter has matic left");
    assert.equal(daiBalance-daiBalance0, 454624917403077760,"DAI balance error");

    //to Native
    const orderId2 = 1;
    const fromTokenAmount2 = ethers.utils.parseUnits('454624917403077760', 18);
    const minReturnAmount2 = 0;

    console.log("before FTM Balance: " + await account.getBalance());
    console.log("before DAI Balance: " + await DAI.balanceOf(account.address));

    // node1
    const mixAdapter2 = [
        spiritswapV2Adapter.address
    ];
    const assertTo2 = [
        poolAddress
    ];
    const weight2 = 10000;
    const rawData2 = [packRawData(tokenConfig.tokens.DAI.baseTokenAddress,tokenConfig.tokens.WFTM.baseTokenAddress,weight2,poolAddress)];

    const moreInfo2 = "0x"
    const extraData2 = [moreInfo2];
    const router2 = [mixAdapter2, assertTo2, rawData2, extraData2, DAI.address];

    // layer1
    const layer2 = [router2];

    const baseRequest2 = [
        DAI.address,
        tokenConfig.tokens.FTM.baseTokenAddress,
        fromTokenAmount2,
        minReturnAmount2,
        deadLine,
    ]

    await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount2);
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId2,
        baseRequest2,
        [fromTokenAmount2],
        [layer2],
        pmmReq
    );

    let daiBalance2 = await DAI.balanceOf(account.address)
    console.log("after FTM Balance: " + await account.getBalance());
    console.log("after DAI Balance: " + daiBalance2);

    let adapterBalance2 = await ethers.provider.getBalance(quickswapAdapter.address)
    let dexRouterBalance2 = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance2, 0,"adapter has matic left");
    assert.equal(dexRouterBalance2, 0,"dexRouter has matic left");
    assert.equal(daiBalance2.toString(), daiBalance0.toString(),"DAI balance error")

}
*/

async function main() {
    //await executeNative();
    await executeWFTM2DAI();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

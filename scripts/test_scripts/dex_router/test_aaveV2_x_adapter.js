const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")

//tokenConfig = getConfig("polygon")
tokenConfig = getConfig("eth")

async function executeBase2Quote() {
    const pmmReq = []
    // Network polygon
    //await setForkNetWorkAndBlockNumber('polygon',42438815);
    await setForkNetWorkAndBlockNumber('eth',17191559);


    const accountAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";//0x358506b4C5c441873AdE429c5A2BE777578E2C6f
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        //tokenConfig.tokens.amUSDT.baseTokenAddress// aave matic USDT
        tokenConfig.tokens.aUSDT.baseTokenAddress// aave USDT
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    //const LENDINGPOOL = "0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf";//polygon
    const LENDINGPOOL = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9";//eth
    AaveV2Adapter = await ethers.getContractFactory("AaveV2Adapter");
    aaveV2Adapter = await AaveV2Adapter.deploy(LENDINGPOOL);
    await aaveV2Adapter.deployed();

    // transfer 1 USDT to adapter
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);

    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = LENDINGPOOL;//lending pool


    // console.log("before Base Balance: " + await Base.balanceOf(account.address));
    // console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

    const mixAdapter1 = [
        aaveV2Adapter.address
    ];
    const assertTo1 = [
        aaveV2Adapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        "0" +                          // 0/8
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")  //  Pool
    ];
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address","address","bool"],
        [Base.address,Quote.address,true]
    )
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, Base.address];

    // layer1
    const layer1 = [router1];
    const orderId = 0;

    const baseRequest = [
        Base.address,
        Quote.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await Base.connect(account).approve(tokenApprove.address, fromTokenAmount);
   
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    //console.log(tx);
    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
}

async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
});
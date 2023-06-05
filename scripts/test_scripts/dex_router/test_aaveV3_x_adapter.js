const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")

tokenConfig = getConfig("polygon")
//tokenConfig = getConfig("eth")

async function executeBase2Quote() {
    const pmmReq = []
    // Network polygon
    await setForkNetWorkAndBlockNumber('polygon',43080909);
    //await setForkNetWorkAndBlockNumber('eth',17327904);


    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";//0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.aPolUSDC.baseTokenAddress// aave polygon USDC
        //tokenConfig.tokens.aEthUSDC.baseTokenAddress// aave Ethereum USDC
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WMATIC.baseTokenAddress);

    const V3POOL = "0x794a61358d6845594f94dc1db02a252b5b4814ad";//polygon or op、arb、ftm、avax
    //const V3POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";//eth
    AaveV3Adapter = await ethers.getContractFactory("AaveV3Adapter");
    aaveV3Adapter = await AaveV3Adapter.deploy(V3POOL);
    await aaveV3Adapter.deployed();

    // transfer 1 USDT to adapter
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDC.decimals);

    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = V3POOL;//lending pool


    // console.log("before Base Balance: " + await Base.balanceOf(account.address));
    // console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

    const mixAdapter1 = [
        aaveV3Adapter.address
    ];
    const assertTo1 = [
        aaveV3Adapter.address
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
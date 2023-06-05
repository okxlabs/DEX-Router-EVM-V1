const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("eth");


async function executeBase2Quote() {
    const pmmReq = []
    // Network eth
    await setForkNetWorkAndBlockNumber('eth',17272038);


    const accountAddress = "0xde1820f69b3022b8c3233d512993eba8cff29ebb";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    console.log("===== Adapter =====");
    IntegrationTestAdapter = await ethers.getContractFactory("IntegralAdapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy("0xd17b3c9784510E33cD5B87b490E79253BcD81e2E");
    await integrationTestAdapter.deployed();


    // transfer 1 USDT to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits("5099.819818", tokenConfig.tokens.USDC.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x6ec472b613012a492693697FA551420E60567eA7";//eth USDC- USDT pool



    const mixAdapter1 = [
        integrationTestAdapter.address
    ];
    const assetTo1 = [
        integrationTestAdapter.address//or poolAddress
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        "0" +                          // 0/8
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")  // Pool
    ];
    //moreInfo
    //const gasLimit = 500000;
    const moreInfo1 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256", "uint256", "uint32"],
        [Base.address, Quote.address, fromTokenAmount, minReturnAmount, deadLine]
    )
    const extraData1 = [moreInfo1];
    const router1 = [mixAdapter1, assetTo1, rawData1, extraData1, Base.address];

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
   
    console.log("\n================== smartSwapByOrderId ==================");
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
}

// Compare TX
// https://etherscan.io/tx/0x96af3882334be2039c01de273249c3fb9af5225e6fc782fba3569ed13ce31b29
async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("avax");


async function executeBase2Quote() {
    const pmmReq = []
    // Network avax
    await setForkNetWorkAndBlockNumber('avax',30371930);


    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
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


    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WAVAX.baseTokenAddress);

    console.log("===== Adapter =====");
    IntegrationTestAdapter = await ethers.getContractFactory("AxialAdapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy();
    await integrationTestAdapter.deployed();


    // transfer 1 USDT to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits("0.1", tokenConfig.tokens.USDT.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0xa0f6397FEBB03021F9BeF25134DE79835a24D76e";//USDC-USDt 0.1USDC



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
    const BaseIndex = '0';//this adapter need index of token address
    const QuoteIndex = '1';
    const moreInfo1 = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "address", "uint8", "uint8"],
      [FOREVER, Base.address, Quote.address, BaseIndex, QuoteIndex]
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

// Compare TX：
// https://snowtrace.io/tx/0xf3da55bf95adae7ef6ef12f4042dd5ee781ecf9640027ad76300014f8ac9fae8
async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

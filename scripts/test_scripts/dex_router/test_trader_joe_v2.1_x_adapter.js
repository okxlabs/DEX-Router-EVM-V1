const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("arb");


async function executeBase2Quote() {
    const pmmReq = []
    // Network arbitrum 
    await setForkNetWorkAndBlockNumber('arbitrum',94563814);


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

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    console.log("===== Adapter =====");
    IntegrationTestAdapter = await ethers.getContractFactory("TraderJoeV2P1Adapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy();
    await integrationTestAdapter.deployed();


    // transfer 1 USDT to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDC.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x0242DD3b2e792CdBD399cc6195951bC202Aee97B";//arb USDC- USDT pool



    const mixAdapter1 = [
        integrationTestAdapter.address
    ];
    const assetTo1 = [
        poolAddress//or poolAddress
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
    const moreInfo1 = "0x"
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
// https://arbiscan.io/tx/0x428e281f92b5b5245276b126f6ecc5d86a81918f5b20d9fec6ceb71e69382035

async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

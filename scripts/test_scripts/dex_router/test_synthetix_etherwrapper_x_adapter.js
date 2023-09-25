const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils");
tokenConfig = getConfig("eth");

//need to change network、base and quote、parameter in initDexRouter、fromtokenamount
//poolAddress、assetTo1 、moreInfo1
async function executeBase2Quote() {
    const pmmReq = []
    // Network eth
    await setForkNetWorkAndBlockNumber('eth',18133086);


    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.sETH.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress    
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);//eth op and arb

    console.log("===== Adapter =====");
    IntegrationTestAdapter = await ethers.getContractFactory("SynthetixEtherWrapperAdapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy();
    await integrationTestAdapter.deployed();


    // transfer 0.0004 sETH to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits('0.0004',tokenConfig.tokens.sETH.decimals);//fromTokenAmount
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x0000000000000000000000000000000000000000";


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
    const moreInfo1 = ethers.utils.defaultAbiCoder.encode(
        ["bool"],
        [false]
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
// https://etherscan.io/tx/0xa08515a2a1cb0832e535d45403ebec2f38e4485140fd2d4b91f8e2360768a762
async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
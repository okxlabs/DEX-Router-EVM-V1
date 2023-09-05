const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils");
//tokenConfig = getConfig("op");
tokenConfig = getConfig("eth");

//need to change network、base and quote、parameter in initDexRouter、fromtokenamount
//poolAddress、assetTo1 、moreInfo1
async function executeBase2Quote() {
    const pmmReq = []
    // Network bsc
    //await setForkNetWorkAndBlockNumber('op',42438815);
    await setForkNetWorkAndBlockNumber('eth',17967445);


    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    //await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

    Base = await ethers.getContractAt(
        "MockERC20",
        //tokenConfig.tokens.DAI.baseTokenAddress
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        //tokenConfig.tokens.sUSD.baseTokenAddress
        tokenConfig.tokens.sETH.baseTokenAddress    
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);//op and arb

    console.log("===== Adapter =====");
    IntegrationTestAdapter = await ethers.getContractFactory("WrappedSynthetixAdapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy();
    await integrationTestAdapter.deployed();


    // transfer 1 USDT to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits('0.01',tokenConfig.tokens.WETH.decimals);//fromTokenAmount
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x0000000000000000000000000000000000000000";//poolAddress or wrapper



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
    const wrapper = "0xCea392596F1AB7f1d6f8F241967094cA519E6129";//this adapter need wrapper
    //wrapper(op susd):0xad32aA4Bff8b61B4aE07E3BA437CF81100AF0cD7
    //wrapper(op seth):0x6202A3B0bE1D222971E93AaB084c6E584C29DB70
    //wrapper(eth susd):0xE01698760Ec750f5f1603CE84C148bAB99cf1A74
    //wrapper(eth seth):0xCea392596F1AB7f1d6f8F241967094cA519E6129

    const moreInfo1 = ethers.utils.defaultAbiCoder.encode(
        ["address","address","address"],
        [Base.address,Quote.address,wrapper]
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

// Compare TX：dopple
// https://bscscan.com/tx/0xec7c09bac2598d6c8f3edd151cde27dda88dcff8552450c525c2958d43569099
async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("eth");


async function executeBase2Quote() {
    const pmmReq = []
    // Network eth
    await setForkNetWorkAndBlockNumber('eth',17976090);


    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.xfETH.baseTokenAddress
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    


    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);//eth

    console.log("===== Adapter =====");
    IntegrationTestAdapter = await ethers.getContractFactory("XfaiAdapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy();
    await integrationTestAdapter.deployed();


    // transfer 1 USDC to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDC.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x1d2e5a754A356d4D9B6a9D79378F9784c0c9aAC0";//USDC-xfETH



    const mixAdapter1 = [
        integrationTestAdapter.address
    ];
    const assetTo1 = [
        poolAddress
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
        [ "address"],
        [Base.address]
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
    console.log("dexrouter address is "+dexRouter.address);
    console.log("tokenApprove address is "+tokenApprove.address);
   
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

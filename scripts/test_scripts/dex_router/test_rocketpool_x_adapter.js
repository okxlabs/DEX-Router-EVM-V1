const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("eth")


async function executeBase2Quote() {
    const pmmReq = []
    // Network eth
    await setForkNetWorkAndBlockNumber('eth',17191559);


    const accountAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";//0x358506b4C5c441873AdE429c5A2BE777578E2C6f
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.rETH.baseTokenAddress
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    const DEPOSITPOOL = "0xDD3f50F8A6CafbE9b31a427582963f465E745AF8";
    RocketpoolAdapter = await ethers.getContractFactory("RocketpoolAdapter");
    rocketpoolAdapter = await RocketpoolAdapter.deploy(Quote.address,DEPOSITPOOL,Base.address);
    await rocketpoolAdapter.deployed();

    // transfer 0.2 WETH to adapter
    const fromTokenAmount = ethers.utils.parseUnits("0.2", tokenConfig.tokens.WETH.decimals);

    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0xDD3f50F8A6CafbE9b31a427582963f465E745AF8";//depositpool



    // console.log("before Base Balance: " + await Base.balanceOf(account.address));
    // console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

    const mixAdapter1 = [
        rocketpoolAdapter.address
    ];
    const assertTo1 = [
        rocketpoolAdapter.address
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
        ["bool"],
        [true]
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
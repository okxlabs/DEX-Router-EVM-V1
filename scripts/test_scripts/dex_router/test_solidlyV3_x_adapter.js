const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")

tokenConfig = getConfig("eth");


async function executeBase2Quote() {
    const pmmReq = []

    // Network eth
    await setForkNetWorkAndBlockNumber('eth',18304515);


    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x53444835ec58000000");

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    


    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);//eth, op and arb

    console.log("===== Adapter =====");
    //const factoryAddr = "0x735BB16affe83A3DC4dC418aBCcF179617Cf9FF2";// solidlyv3 factoryAddress on eth
    IntegrationTestAdapter = await ethers.getContractFactory("SolidlyV3Adapter");
    integrationTestAdapter = await IntegrationTestAdapter.deploy();
    await integrationTestAdapter.deployed();//WBNB/WETH


    // transfer 1 USDC to Pool or adapter
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDC.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;

    const poolAddress = "0xaFED85453681dc387EE0E87b542614722EE2CfeD";//solildyV3（eth）USDT-USDC 1USDT


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
        ["uint160", "bytes"],
        [
          // "888971540474059905480051",
          0,
          ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint24"],
            [
              Base.address,
              Quote.address,
              100,
            ]
          )
        ]
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

// Compare TX：pancakeswapV3(bsc)
// https://bscscan.com/tx/0x40a5042a0b2ea7b738dc7317661dff8c850189c306c55afbd6b3186c6bb74b87
// Compare TX：pancakeswapV3(eth)
// https://etherscan.io/tx/0xc3dc432f2d6613afbd987ba2cad4489538f48f73837ad255aa0fa89ab8a6ca78

async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

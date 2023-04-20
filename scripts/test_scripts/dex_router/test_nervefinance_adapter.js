let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
const { startMockAccount } = require("../../tools/chain");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("./utils");


async function executeSwap() {
    let pmmReq = [];
    await setForkNetWorkAndBlockNumber("bsc", 25856404);

    let accountAddress = "0xf977814e90da44bfa03b6295a0616a897441acec";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);

    // BUSD-USDC
    BUSD = await ethers.getContractAt(
        "MockERC20",
        "0xe9e7cea3dedca5984780bafc599bd69add087d56"
    )

    USDC = await ethers.getContractAt(
        "MockERC20",
        "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    NerveFinanceAdapter = await ethers.getContractFactory("NerveFinanceAdapter");
    NerveFinanceAdapter = await NerveFinanceAdapter.deploy();
    await NerveFinanceAdapter.deployed();


    let fromTokenAmount =  ethers.utils.parseUnits('1000', tokenConfig.tokens.BUSD.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x1B3771a66ee31180906972580adE9b81AFc5fCDc"; 
    console.log("before Account BUSD Balance: " + await BUSD.balanceOf(account.address));
    console.log("before Account USDC Balance: " + await USDC.balanceOf(account.address));

    let mixAdapter1 = [
        NerveFinanceAdapter.address
    ];
    let assertTo1 = [
        NerveFinanceAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');


    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint8", "uint8", "uint256"],
        [
            BUSD.address,
            USDC.address,
            0,
            2,
            deadLine
        ]
    )

    let rawData1 = [
        "0x" + 
        direction(BUSD.address, USDC.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, BUSD.address];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        BUSD.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await BUSD.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

    console.log("after Account BUSD Balance: " + await BUSD.balanceOf(account.address));
    console.log("after Account USDC Balance: " + await USDC.balanceOf(account.address));
} 

async function main() {
    console.log(" ============= Nerve StableCoin pool ===============");
    await executeSwap();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
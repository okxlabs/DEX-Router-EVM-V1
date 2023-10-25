let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
// const { startMockAccount } = require("../../tools/chain");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("./utils");


async function executeSwap() {
    let pmmReq = [];
    await setForkNetWorkAndBlockNumber("bsc", 32102658);

    let accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x53444835ec580000")

    // BSCUSD-WETH
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    BSCUSD = await ethers.getContractAt(
        "MockERC20",
        "0x55d398326f99059fF775485246999027B3197955"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    DODOV3Adapter = await ethers.getContractFactory("DODOV3Adapter");
    DODOV3Adapter = await DODOV3Adapter.deploy();
    await DODOV3Adapter.deployed();


    let fromTokenAmount =  ethers.utils.parseUnits('1', 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    //no need for poolAddress
    let poolAddress = "0x7979Dd3C3Ac7446F0a05D0BB700a3dF48D36b4cB"; 
    console.log("before Account BSCUSD Balance: " + await BSCUSD.balanceOf(account.address));
    console.log("before Account WETH Balance: " + await WETH.balanceOf(account.address));

    let mixAdapter1 = [
        DODOV3Adapter.address
    ];
    let assertTo1 = [
        DODOV3Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            BSCUSD.address,
            WETH.address
        ]
    )

    let rawData1 = [
        "0x" + 
        "8" +  // 0: sellBase / 8: sellQuote
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, BSCUSD.address];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        BSCUSD.address,
        WETH.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await BSCUSD.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

    console.log("after Account BSCUSD Balance: " + await BSCUSD.balanceOf(account.address));
    console.log("after Account WETH Balance: " + await WETH.balanceOf(account.address));
} 

async function main() {
    console.log(" ============= DODO V3 BSCUSD-WETH ===============");
    await executeSwap();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
// const { startMockAccount } = require("../../tools/chain");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
tokenConfig = getConfig("arb");
let { initDexRouter, direction, FOREVER } = require("./utils");


async function executeSwap() {
    let pmmReq = [];
    await setForkNetWorkAndBlockNumber("arbitrum", 130376151);

    let accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x53444835ec580000")

    // USDT-USDCe
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    ) 

    USDCe = await ethers.getContractAt(
        "MockERC20",
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
    ) 

    let { dexRouter, tokenApprove } = await initDexRouter();

    RamsesV2Adapter = await ethers.getContractFactory("RamsesV2Adapter");
    // factory：0xAA2cd7477c451E703f3B9Ba5663334914763edF8
    RamsesV2Adapter = await RamsesV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await RamsesV2Adapter.deployed();


    let fromTokenAmount =  ethers.utils.parseUnits('2', 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    //no need for poolAddress
    let poolAddress = "0x6059Cf1C818979BCCAc5d1F015E1B322D154592f"; 
    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before Account USDCe Balance: " + await USDCe.balanceOf(account.address));

    let mixAdapter1 = [
        RamsesV2Adapter.address
    ];
    let assertTo1 = [
        RamsesV2Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');

    data = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            USDT.address,
            USDCe.address
        ]
    )

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            data
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
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, USDT.address];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        USDT.address,
        USDCe.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

    console.log("after Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("after Account USDCe Balance: " + await USDCe.balanceOf(account.address));
} 

async function main() {
    console.log(" ============= Ramses V2 USDT-USDCe ===============");
    await executeSwap();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
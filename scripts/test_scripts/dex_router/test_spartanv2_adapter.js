let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
const { startMockAccount } = require("../../tools/chain");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("./utils");


async function executeSwap() {
    let pmmReq = [];
    await setForkNetWorkAndBlockNumber("bsc", 31153352);

    let accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x53444835ec580000")

    // UST-SPARTA
    UST = await ethers.getContractAt(
        "MockERC20",
        "0x23396cF899Ca06c4472205fC903bDB4de249D6fC"
    )

    SPARTA = await ethers.getContractAt(
        "MockERC20",
        "0x3910db0600eA925F63C36DdB1351aB6E2c6eb102"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    SpartanV2Adapter = await ethers.getContractFactory("SpartanV2Adapter");
    SpartanV2Adapter = await SpartanV2Adapter.deploy('0xf73d255d1E2b184cDb7ee0a8A064500eB3f6b352');
    await SpartanV2Adapter.deployed();


    let fromTokenAmount =  ethers.utils.parseUnits('1', 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    //no need for poolAddress
    let poolAddress = "0x0000000000000000000000000000000000000000"; 
    console.log("before Account UST Balance: " + await UST.balanceOf(account.address));
    console.log("before Account SPARTA Balance: " + await SPARTA.balanceOf(account.address));

    let mixAdapter1 = [
        SpartanV2Adapter.address
    ];
    let assertTo1 = [
        SpartanV2Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            UST.address,
            SPARTA.address
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
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, UST.address];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        UST.address,
        SPARTA.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await UST.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

    console.log("after Account UST Balance: " + await UST.balanceOf(account.address));
    console.log("after Account SPARTA Balance: " + await SPARTA.balanceOf(account.address));
} 

async function main() {
    console.log(" ============= SPARTAN V2 UST-SPARTA ===============");
    await executeSwap();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
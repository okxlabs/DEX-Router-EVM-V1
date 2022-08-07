let { ethers } = require("hardhat");
require("../../../tools");
let { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("../utils")


async function deployContract() {
    MstableAdapter = await ethers.getContractFactory("MstableAdapter");
    MstableAdapter = await MstableAdapter.deploy();
    await MstableAdapter.deployed();
    return MstableAdapter
}

async function executeMainPool(MstableAdapter) {
    const pmmReq = []

    let accountAddress = "0xed55D1B71b6bfA952ddBC4f24375C91652878560";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    // WETH
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));
    
    let fromTokenAmount = ethers.utils.parseUnits("10000", tokenConfig.tokens.USDT.decimals);
    await USDT.connect(account).transfer(MstableAdapter.address, fromTokenAmount);

    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5"; 

    let mixAdapter1 = [
        MstableAdapter.address
    ];
    let assertTo1 = [
        account.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];

    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDT.address,
            DAI.address,
            FOREVER
        ]
      )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, USDT.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        USDT.address,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account USDT  Balance: " + await USDT.balanceOf(account.address));
    console.log("after Account DAI Balance: " + await DAI.balanceOf(account.address));
}


async function main() {
    MstableAdapter = await deployContract()
    console.log(" ============= executeSellBase ===============");
    await executeMainPool(MstableAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });








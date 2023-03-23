let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function executeUSDC2USDT() {
    let pmmReq = [];
    await setForkNetWorkAndBlockNumber("bsc", 26652695);

    let accountAddress = "0x4cf3b52fb87d971dae37247f0cc7c64110c6ba7c";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);

    await setBalance(accountAddress, "0xe11853444835ec580000");

    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    console.log("before Account USDC Balance: " + await USDC.balanceOf(account.address));
    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    
    let { dexRouter, tokenApprove } = await initDexRouter(USDC.address);

    PancakeAdapter = await ethers.getContractFactory("PancakestableAdapter");
    pancakeAdapter = await PancakeAdapter.deploy();
    await pancakeAdapter.deployed();

    let fromTokenAmount =  ethers.utils.parseUnits("505", 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x3EFebC418efB585248A0D2140cfb87aFcc2C63DD"; 

    let mixAdapter1 = [
        pancakeAdapter.address
    ];
    let assertTo1 = [
        pancakeAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDC.baseTokenAddress, tokenConfig.tokens.USDT.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    console.log(rawData1);

    let moreinfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            tokenConfig.tokens.USDC.baseTokenAddress,
            tokenConfig.tokens.USDT.baseTokenAddress,
            1,
            0
        ]
      )
    let extraData1 = [moreinfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1,tokenConfig.tokens.USDC.baseTokenAddress];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        tokenConfig.tokens.USDC.baseTokenAddress,
        tokenConfig.tokens.USDT.baseTokenAddress,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDC.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

    console.log("after Account USDT Balance: " + await USDT.balanceOf(account.address));
}

async function main() {
    await executeUSDC2USDT();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
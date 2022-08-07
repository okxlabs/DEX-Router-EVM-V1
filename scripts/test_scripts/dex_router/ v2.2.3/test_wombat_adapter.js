let { ethers } = require("hardhat");
require("../../../tools");
let { getConfig } = require("../../../config");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("../utils")


async function usdPool() {
    const pmmReq = []

    let accountAddress = "0xf977814e90da44bfa03b6295a0616a897441acec";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    // USDC
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    console.log("before Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before Account USDC Balance: " + await USDC.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();

    WombatAdapter = await ethers.getContractFactory("WombatAdapter");
    WombatAdapter = await WombatAdapter.deploy();
    await WombatAdapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("500000", tokenConfig.tokens.USDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0"; 
    await USDT.connect(account).transfer(WombatAdapter.address, fromTokenAmount);
    console.log("before WombatAdapter USDT Balance: " + await USDT.balanceOf(WombatAdapter.address));

    let mixAdapter1 = [
        WombatAdapter.address
    ];
    let assertTo1 = [
        account.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.USDC.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let  moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDT.address,
            USDC.address,
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
        USDC.address,
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

    console.log("after Account USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("after Account USDC Balance: " + await USDC.balanceOf(account.address));
}


async function main() {
    await usdPool()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







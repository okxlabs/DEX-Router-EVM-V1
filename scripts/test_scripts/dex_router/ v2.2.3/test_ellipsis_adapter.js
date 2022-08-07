let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("./utils")
require("./utils/test_multi_x_factory");


async function Erc20ToErc20() {
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

    EllipsisAdapter = await ethers.getContractFactory("EllipsisAdapter");
    EllipsisAdapter = await EllipsisAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await EllipsisAdapter.deployed();

    // transfer 500 USDT to curveAdapter
    let fromTokenAmount = ethers.utils.parseUnits("500", tokenConfig.tokens.USDT.decimals);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x160caed03795365f3a589f10c379ffa7d75d4e76"; 
    await USDT.connect(account).transfer(EllipsisAdapter.address, fromTokenAmount);
    console.log("before EllipsisAdapter USDT Balance: " + await USDT.balanceOf(EllipsisAdapter.address));

    let mixAdapter1 = [
        EllipsisAdapter.address
    ];
    let assertTo1 = [
        EllipsisAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.USDC.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            USDT.address,
            USDC.address,
            2,
            1
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
    await Erc20ToErc20()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







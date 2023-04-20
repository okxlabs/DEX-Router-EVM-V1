let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("arbitrum");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function deployWoofiAdapter() {
    WoofiAdapter = await ethers.getContractFactory("WoofiAdapter");
    WoofiAdapter = await WoofiAdapter.deploy();
    await WoofiAdapter.deployed();
    return WoofiAdapter
}

// Arbitrum 
async function wooFiSellBase(WoofiAdapter) {
    let pmmReq = []

    // WETH holder
    let accountAddress = "0xeaa3fce9fdf74a3c48cac4c1a81e08ef14027901";

    // woofi pool
    let poolAddress = "0xeFF23B4bE1091b53205E35f3AfCD9C7182bf3062"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // WETH
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    // zyber token
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("1", 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        WoofiAdapter.address
    ];
    let assertTo1 = [
        WoofiAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let  moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            fromToken.address,
            toToken.address
        ]
      )

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    
    await fromToken.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await toToken.balanceOf(account.address));

    console.log("token left: ", await toToken.balanceOf(WoofiAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function wooFiSellQuote(WoofiAdapter) {
    let pmmReq = []

    // WETH holder
    let accountAddress = "0xeaa3fce9fdf74a3c48cac4c1a81e08ef14027901";

    // woofi pool
    let poolAddress = "0xeFF23B4bE1091b53205E35f3AfCD9C7182bf3062"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // WETH
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
  
    // zyber token
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("1", 18);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        WoofiAdapter.address
    ];
    let assertTo1 = [
        WoofiAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let  moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            fromToken.address,
            toToken.address
        ]
      )

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    
    await fromToken.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await toToken.balanceOf(account.address));

    console.log("token left: ", await toToken.balanceOf(WoofiAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}


async function main() {

    WoofiAdapter = await deployWoofiAdapter();
    console.log("ZyberAdapter.address", WoofiAdapter.address);
    
    console.log(" ========= wooFiSellBase ======")
    await wooFiSellBase(WoofiAdapter)

    console.log(" ========= zyber stable ======")
    await wooFiSellQuote(WoofiAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







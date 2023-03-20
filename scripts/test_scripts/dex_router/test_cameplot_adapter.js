let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("arbitrum");
let { initDexRouter, direction, FOREVER } = require("./utils")

async function deployAdapter() {
    CameplotAdapter = await ethers.getContractFactory("CameplotAdapter");
    CameplotAdapter = await CameplotAdapter.deploy();
    await CameplotAdapter.deployed();
    return CameplotAdapter
}

// USDC <-> USDT
async function executeComeplotStableShellBase(CameplotAdapter) {
    let pmmReq = []

    let accountAddress = "0x62383739d68dd0f844103db8dfb05a7eded5bbe6";
    let poolAddress = "0x1C31fB3359357f6436565cCb3E982Bc6Bf4189ae"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
        )

    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
        )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("2000", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    console.log("before Account fromToken Balance: " +  await toToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await fromToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        CameplotAdapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(toToken.address, fromToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let moreInfo = "0x";
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

    console.log("after Account fromToken Balance: " +  await toToken.balanceOf(account.address));
    console.log("after Account toToken Balance: " + await fromToken.balanceOf(account.address));

}

// USDC <-> USDT
async function executeComeplotStableShellQuote(CameplotAdapter) {
    let pmmReq = []

    let accountAddress = "0x8b8149dd385955dc1ce77a4be7700ccd6a212e65";
    let poolAddress = "0x1C31fB3359357f6436565cCb3E982Bc6Bf4189ae"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("2000", 6);
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
        CameplotAdapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.USDC.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let moreInfo = "0x";
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

    console.log("token left: ", await toToken.balanceOf(CameplotAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function executeComeplotUniswapShellQuote(CameplotAdapter) {
    let pmmReq = []

    let accountAddress = "0x62383739d68dd0f844103db8dfb05a7eded5bbe6";
    let poolAddress = "0x97b192198d164C2a1834295e302B713bc32C8F1d"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("2000", 6);
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
        CameplotAdapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.USDC.baseTokenAddress, tokenConfig.tokens.WETH.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let moreInfo = "0x";
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

    console.log("token left: ", await toToken.balanceOf(CameplotAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}


async function main() {

    CameplotAdapter = await deployAdapter();
    console.log("CameplotAdapter.address", CameplotAdapter.address);
    
    console.log(" ============= Campletplot Stable Pool Shell Base  ===============");
    await executeComeplotStableShellBase(CameplotAdapter)

    console.log(" ============= Campletplot Stable Pool Shell Quote  ===============");
    await executeComeplotStableShellQuote(CameplotAdapter);

    console.log(" ============= Campletplot Uniswap Pool ===============");
    await executeComeplotUniswapShellQuote(CameplotAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







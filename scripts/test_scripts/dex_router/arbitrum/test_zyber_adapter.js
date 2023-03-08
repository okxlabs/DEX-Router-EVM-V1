let { ethers } = require("hardhat");
require("../../../tools");
let { getConfig } = require("../../../config");
tokenConfig = getConfig("arbitrum");
let { initDexRouter, direction, FOREVER } = require("../utils")

async function deployAdapter() {
    UniAdapter = await ethers.getContractFactory("UniAdapter");
    UniAdapter = await UniAdapter.deploy();
    await UniAdapter.deployed();
    return UniAdapter
}

async function deployZyberStableAdapter() {
    ZyberStableAdapter = await ethers.getContractFactory("ZyberStableAdapter");
    ZyberStableAdapter = await ZyberStableAdapter.deploy();
    await ZyberStableAdapter.deployed();
    return ZyberStableAdapter
}

async function zyberUniswap(ZyberAdapter) {
    let pmmReq = []

    let accountAddress = "0xc31e54c7a869b9fcbecc14363cf510d1c41fa443";
    let poolAddress = "0xf69223B75D9CF7c454Bb44e30a3772202bEE72CF"; 

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
        "0x3B475F6f2f41853706afc9Fa6a6b8C5dF1a2724c"
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
        ZyberAdapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
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

    console.log("token left: ", await toToken.balanceOf(ZyberAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function zyberStable(ZyberStableAdapter) {
    let pmmReq = []

    let accountAddress = "0x8b8149dd385955dc1ce77a4be7700ccd6a212e65";
    let poolAddress = "0x969f7699fbB9C79d8B61315630CDeED95977Cfb8"; 

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
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("200", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let is_underlying = false;

    console.log("before Account fromToken Balance: " +  await fromToken.balanceOf(account.address));
    console.log("before Account toToken Balance: " + await toToken.balanceOf(account.address));

    // arguments
    // let requestParam1 = [
    //     tokenConfig.tokens.USDT.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    let mixAdapter1 = [
        ZyberStableAdapter.address
    ];
    let assertTo1 = [
        ZyberStableAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  
    ];
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint8", "uint8", "uint256", "bool"],
        [
            fromToken.address,
            toToken.address,
            0,
            1,
            FOREVER,
            is_underlying
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

    console.log("token left: ", await toToken.balanceOf(ZyberStableAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function main() {

    ZyberAdapter = await deployAdapter();
    console.log("ZyberAdapter.address", ZyberAdapter.address);
    
    console.log(" ========= zyberUniswap ======")
    await zyberUniswap(ZyberAdapter)

    ZyberStableAdapter = await deployZyberStableAdapter();
    console.log(" ========= zyber stable ======")

    await zyberStable(ZyberStableAdapter)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







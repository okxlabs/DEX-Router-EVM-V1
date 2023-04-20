let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
tokenConfig = getConfig("bsc");
let { initDexRouter, direction, FOREVER } = require("./utils")


async function deployIzumiAdapter() {
    factory = "0xd7de110bd452aab96608ac3750c3730a17993de0"
    IZumiAdapter = await ethers.getContractFactory("IZumiAdapter");
    IZumiAdapter = await IZumiAdapter.deploy(
        "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
        factory
    );
    await IZumiAdapter.deployed();
    return IZumiAdapter
}

async function X2Y(IZumiAdapter) {
    let pmmReq = []

    let accountAddress = "0x28ec0b36f0819ecb5005cab836f4ed5a2eca4d13";

    // https://bscscan.com/address/0x9e85e816e5c9c6973dc0bc3f0fe58c9f63b3df74
    // tokenX: 0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d address
    // tokenY: 0xb6c53431608e626ac81a9776ac3e999c5556717c address

    let poolAddress = "0x9e85e816e5C9c6973Dc0bc3F0fe58c9f63B3dF74"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // WETH
    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    // pToken
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xb6C53431608E626AC81a9776ac3e999c5556717c"
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await ethers.utils.parseUnits("200", 18);
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
        IZumiAdapter.address
    ];
    let assertTo1 = [
        IZumiAdapter.address
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
        ["address", "address"],
        [
            fromToken.address,
            toToken.address,
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

    console.log("token left: ", await toToken.balanceOf(IZumiAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function Y2X(IZumiAdapter) {
    let pmmReq = []

    let accountAddress = "0x28ec0b36f0819ecb5005cab836f4ed5a2eca4d13";

    // https://bscscan.com/address/0x9e85e816e5c9c6973dc0bc3f0fe58c9f63b3df74
    // tokenX: 0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d address
    // tokenY: 0xb6c53431608e626ac81a9776ac3e999c5556717c address

    let poolAddress = "0x9e85e816e5C9c6973Dc0bc3F0fe58c9f63B3dF74"; 

    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xb6C53431608E626AC81a9776ac3e999c5556717c"
    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();

    // transfer ETH to curveAdapter
    let fromTokenAmount = await fromToken.balanceOf(accountAddress);
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
        IZumiAdapter.address
    ];
    let assertTo1 = [
        IZumiAdapter.address
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
        ["address", "address"],
        [
            fromToken.address,
            toToken.address,
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

    console.log("token left: ", await toToken.balanceOf(IZumiAdapter.address))
    console.log("token left: ", await toToken.balanceOf(dexRouter.address))
}

async function main() {

    IZumiAdapter = await deployIzumiAdapter();
    console.log("IZumiAdapter.address", IZumiAdapter.address);
    
    console.log(" ========= X2Y ======")
    await X2Y(IZumiAdapter)

    console.log(" ========= Y2X ======")
    await Y2X(IZumiAdapter)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







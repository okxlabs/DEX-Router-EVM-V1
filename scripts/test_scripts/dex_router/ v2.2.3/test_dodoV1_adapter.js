let { ethers } = require("hardhat");
require("../../../tools");
let { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("../utils")

async function deployContract() {
    dodoSellHelper = "0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb"
    DODOV1Adapter = await ethers.getContractFactory("DODOV1Adapter");
    DODOV1Adapter = await DODOV1Adapter.deploy(dodoSellHelper);
    await DODOV1Adapter.deployed();
    return DODOV1Adapter
}

async function executeSellBase(DODOV1Adapter) {
    const pmmReq = []

    let accountAddress = "0x1c11ba15939e1c16ec7ca1678df6160ea2063bc5";
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);
  
    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // USDT
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    // WETH
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    console.log("before Account USDC Balance: " + await USDC.balanceOf(account.address));
    console.log("before Account WETH Balance: " + await WETH.balanceOf(account.address));
    
    let fromTokenAmount = ethers.utils.parseEther("1");
    await WETH.connect(account).transfer(DODOV1Adapter.address, fromTokenAmount);


    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x75c23271661d9d143DCb617222BC4BEc783eff34"; 

    let mixAdapter1 = [
        DODOV1Adapter.address
    ];
    let assertTo1 = [
        account.address
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
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        WETH.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after Account USDC  Balance: " + await USDC.balanceOf(account.address));
    console.log("after Account WETH Balance: " + await WETH.balanceOf(account.address));
}


async function main() {
    DODOV1Adapter = await deployContract()
    console.log(" ============= executeSellBase ===============");
    await executeSellBase(DODOV1Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });








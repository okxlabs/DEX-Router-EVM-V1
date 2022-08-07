let { ethers } = require("hardhat");
require("../../../tools");
let { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("../utils")

async function deployContract() {
    ShellAdapter = await ethers.getContractFactory("ShellAdapter");
    ShellAdapter = await ShellAdapter.deploy();
    await ShellAdapter.deployed();
    return ShellAdapter
}

async function executeMainPool(ShellAdapter) {
    const pmmReq = []

    let accountAddress = "0xda8A87b7027A6C235f88fe0Be9e34Afd439570b5";
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
    
    let fromTokenAmount = ethers.utils.parseUnits("1000", tokenConfig.tokens.USDT.decimals);
    await USDT.connect(account).transfer(ShellAdapter.address, fromTokenAmount);

    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x8f26D7bAB7a73309141A291525C965EcdEa7Bf42"; 

    let mixAdapter1 = [
        ShellAdapter.address
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
    ShellAdapter = await deployContract()
    console.log(" ============= execute USD Pool ===============");
    await executeMainPool(ShellAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });








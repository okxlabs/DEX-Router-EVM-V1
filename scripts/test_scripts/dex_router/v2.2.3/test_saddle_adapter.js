let { ethers } = require("hardhat");
require("../../../tools");
let { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");
let { initDexRouter, direction, FOREVER } = require("../utils")

async function deployContract() {
    SaddleAdapter = await ethers.getContractFactory("SaddleAdapter");
    SaddleAdapter = await SaddleAdapter.deploy();
    await SaddleAdapter.deployed();
    return SaddleAdapter
  }

async function executeMainPool(SaddleAdapter) {
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
    
    let fromTokenAmount = ethers.utils.parseUnits("1000", tokenConfig.tokens.USDT.decimals);
    await USDT.connect(account).transfer(SaddleAdapter.address, fromTokenAmount);

    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x3911F80530595fBd01Ab1516Ab61255d75AEb066"; 

    let mixAdapter1 = [
        SaddleAdapter.address
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

    const is_underlying = true
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint8", "uint8", "uint256", "bool"],
      [
          USDT.address,
          DAI.address,
          2,
          0,
          FOREVER,
          is_underlying
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
    SaddleAdapter = await deployContract()
    console.log(" ============= execute Base Pool ===============");
    await executeMainPool(SaddleAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });








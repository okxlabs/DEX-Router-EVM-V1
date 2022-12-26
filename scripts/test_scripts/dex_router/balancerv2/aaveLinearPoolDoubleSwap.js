const { ethers } = require("hardhat");
require("../../../tools");
const axios = require("axios")
const { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");
require('dotenv').config();
let { initDexRouter, direction, FOREVER } = require("../utils")
const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

async function deployContract() {
    BalancerV2ComposableAdapter = await ethers.getContractFactory("BalancerV2ComposableAdapter");
    BalancerV2ComposableAdapter = await BalancerV2ComposableAdapter.deploy(balancerVault ,tokenConfig.tokens.WETH.baseTokenAddress);
    await BalancerV2ComposableAdapter.deployed();
    return BalancerV2ComposableAdapter
}

// 这里每次修改路径，都要修改moreInfo
async function getMoreInfo() {
    const hipNumber = 2

    hipDetails =  ethers.utils.defaultAbiCoder.encode(
        [ "tuple(bytes32, address, address)", "tuple(bytes32, address, address)"]  ,
        [
            [
                "0x2f4eb100552ef93840d5adc30560e5513dfffacb000000000000000000000334", // Balancer Aave Boosted Pool (USDT) (bb-a-USDT)
                "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
                "0x2F4eb100552ef93840d5aDC30560E5513DFfFACb"  // bb-a-usdt
            ],
            [
                "0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d", // Balancer Aave Boosted StablePool (bb-a-USD)
                "0x2F4eb100552ef93840d5aDC30560E5513DFfFACb", // bb-a-usdt
                "0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83"  // bb-a-usdc
            ]
        ]
      )

    moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["uint8",  "bytes" ], 
        [
            hipNumber,
            hipDetails
        ]
    )
    return moreInfo
}



async function aaveLinearPool(BalancerV2ComposableAdapter) {
    const pmmReq = []
    const accountAddress = "0x96fdc631f02207b72e5804428dee274cf2ac0bcd";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83"
    )

    const fromTokenAmount = ethers.utils.parseUnits("10000", 6);
    const { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const balancerV2PoolAddr = balancerVault; 
    console.log("before fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("before toToken Balance: " + await toToken.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        BalancerV2ComposableAdapter.address
    ];
    const assertTo1 = [
        BalancerV2ComposableAdapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(fromToken.address, toToken.address) +
        "0000000000000000000" +
        weight1 +
        balancerV2PoolAddr.replace("0x", "") 
    ];
    const moreInfo = await getMoreInfo()

    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await fromToken.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("after toToken Balance: " + await toToken.balanceOf(account.address));
    console.log("input amount: ", fromTokenAmount);
}


async function main() {
    BalancerV2ComposableAdapter = await deployContract();
    await aaveLinearPool(BalancerV2ComposableAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
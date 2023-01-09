const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER, packRawData} = require("../utils")
const {assert} = require("chai");

async function USDT2USDC() {
    const pmmReq = []

    const accountAddress = "0x65a0947ba5175359bb457d3b34491edf4cbf7997";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )
    toToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    const { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    KyberElasticAdapter = await ethers.getContractFactory("KyberElasticAdapter");
    KyberElasticAdapter = await KyberElasticAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await KyberElasticAdapter.deployed();

    const fromTokenAmount = ethers.utils.parseUnits("1000", 6)
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const USDT2USDCPool = "0x952FfC4c47D66b454a8181F5C68b6248E18b66Ec"; // USDT-USDC
    console.log("before fromToken Balance: " + await fromToken.balanceOf(account.address));
    console.log("before toToken Balance: " + await toToken.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        KyberElasticAdapter.address
    ];
    const assertTo1 = [
        KyberElasticAdapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(fromToken.address, toToken.address) +
        "0000000000000000000" +
        weight1 +
        USDT2USDCPool.replace("0x", "")  // RND-WETH Pool
    ];
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            // "888971540474059905480051",
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    fromToken.address,
                    toToken.address,
                    10000
                ]
            )
        ]
    )
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
    const permit = []
    await fromToken.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapWithPermit(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        permit
    );

    console.log("after fromToken Balance: " + await fromToken.balanceOf(KyberElasticAdapter.address));
    console.log("after toToken Balance: " + await toToken.balanceOf(account.address));
}


async function main() {
    await USDT2USDC();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

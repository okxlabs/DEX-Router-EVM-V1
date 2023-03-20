const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
tokenConfig = getConfig("arbitrum")
const { initDexRouter, direction, FOREVER, packRawData} = require("../utils")
const {assert} = require("chai");

async function executeWETH2toToken() {
    const pmmReq = []

    const accountAddress = "0xe774E84167c568381aB437486d15401C3c125a6C";
    const uniV3PoolAddr = "0x227Ad861466853783f5956DdbB119235Ff4377b3"; 

    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    fromToken = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"
    )
    
    const { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);

    ZyberV3Adapter = await ethers.getContractFactory("ZyberV3Adapter");
    ZyberV3Adapter = await ZyberV3Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await ZyberV3Adapter.deployed();
    


    const fromTokenAmount = ethers.utils.parseEther('10');
    const minReturnAmount = 0;
    const deadLine = FOREVER;

    
    console.log("before WETH Balance: " + await fromToken.balanceOf(account.address));
    console.log("before toToken Balance: " + await toToken.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        ZyberV3Adapter.address
    ];
    const assertTo1 = [
        ZyberV3Adapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(fromToken.address, toToken.address) +
        "0000000000000000000" +
        weight1 +
        uniV3PoolAddr.replace("0x", "")  // toToken-WETH Pool
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
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,fromToken.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];
    const orderId = 0;
    const baseRequest = [
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

    console.log("after WETH Balance: " + await fromToken.balanceOf(ZyberV3Adapter.address));
    console.log("after toToken Balance: " + await toToken.balanceOf(account.address));
}


async function main() {
    await executeWETH2toToken();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

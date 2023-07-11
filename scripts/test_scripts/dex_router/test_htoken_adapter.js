const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("arbitrum")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executehUSDT2USDT() {
    const pmmReq = []
    await setForkNetWorkAndBlockNumber('artibrum', 103381652);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
      )
  
    hUSDT = await ethers.getContractAt(
        "MockERC20",
        "0x12e59C59D282D2C00f3166915BED6DC2F5e2B5C7"
      )

    const { dexRouter, tokenApprove } = await initDexRouter();

    HtokenAdapter = await ethers.getContractFactory("HtokenAdapter");
    HtokenAdapter = await HtokenAdapter.deploy();
    await HtokenAdapter.deployed();

    await hUSDT.connect(account).transfer(HtokenAdapter.address, ethers.utils.parseUnits("0.9", tokenConfig.tokens.USDT.decimals));

    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);
    const minReturnAmount = 0;

    const poolAddr = "0x18f7402B673Ba6Fb5EA4B95768aABb8aaD7ef18a";
    console.log("before hUSDT Balance: " + await hUSDT.balanceOf(account.address));
    console.log("before USDT Balance: " + await USDT.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        HtokenAdapter.address
    ];
    const assertTo1 = [
        poolAddr
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction("0x12e59C59D282D2C00f3166915BED6DC2F5e2B5C7", tokenConfig.tokens.USDT.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        poolAddr.replace("0x", "")
    ];

    const moreInfo = ethers.utils.defaultAbiCoder.encode(["address", "address"],["0x12e59C59D282D2C00f3166915BED6DC2F5e2B5C7", tokenConfig.tokens.USDT.baseTokenAddress]);
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, hUSDT.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        hUSDT.address,
        USDT.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await hUSDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        0,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log("after hUSDT Balance: " + await hUSDT.balanceOf(HtokenAdapter.address));
    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
}

async function main() {
    await executehUSDT2USDT();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
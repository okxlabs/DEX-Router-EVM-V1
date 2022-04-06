const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executeWETH2RND() {

    await setForkBlockNumber(14446603);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
      )

    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    KyberAdapter = await ethers.getContractFactory("KyberAdapter");
    KyberAdapter = await KyberAdapter.deploy();
    await KyberAdapter.deployed();

    const fromTokenAmount = ethers.utils.parseEther('0.0625');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddr = "0xcE9874C42DcE7fffbE5E48B026Ff1182733266Cb"; // RND-WETH Pool
    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before USDT Balance: " + await USDT.balanceOf(account.address));

    // node1
    const requestParam1 = [
        tokenConfig.tokens.WETH.baseTokenAddress,
        [fromTokenAmount]
    ];
    const mixAdapter1 = [
        KyberAdapter.address
    ];
    const assertTo1 = [
        poolAddr
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.USDT.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        poolAddr.replace("0x", "")  // RND-WETH Pool
    ];
    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1];

    // layer1
    const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        WETH.address,
        USDT.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [request1],
        [layer1],
    );

    console.log("after WETH Balance: " + await WETH.balanceOf(KyberAdapter.address));
    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
}

async function main() {
    await executeWETH2RND();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
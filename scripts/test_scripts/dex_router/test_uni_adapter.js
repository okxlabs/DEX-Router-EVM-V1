const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executeWETH2RND() {
    const pmmReq = []
    await setForkBlockNumber(14446603);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    RND = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.RND.baseTokenAddress
    )

    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    UniV2Adapter = await ethers.getContractFactory("UniAdapter");
    univ2Adapter = await UniV2Adapter.deploy();
    await univ2Adapter.deployed();

    const fromTokenAmount = ethers.utils.parseEther('0.0625');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const uniV2PoolAddr = "0x5449bd1a97296125252db2d9cf23d5d6e30ca3c1"; // RND-WETH Pool
    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        univ2Adapter.address
    ];
    const assertTo1 = [
        uniV2PoolAddr
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.RND.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        uniV2PoolAddr.replace("0x", "")  // RND-WETH Pool
    ];
    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        WETH.address,
        RND.address,
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

    console.log("after WETH Balance: " + await WETH.balanceOf(univ2Adapter.address));
    console.log("after RND Balance: " + await RND.balanceOf(account.address));
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

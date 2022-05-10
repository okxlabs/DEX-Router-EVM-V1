const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")

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

//From and To Native
async function executeNative() {
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

    // from native
    const fromTokenAmount = ethers.utils.parseEther('0.0625');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const uniV2PoolAddr = "0x5449bd1a97296125252db2d9cf23d5d6e30ca3c1"; // RND-WETH Pool

    console.log("before ETH Balance: " + await account.getBalance());
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // node1
    const mixAdapter1 = [
        univ2Adapter.address
    ];
    const assertTo1 = [
        uniV2PoolAddr
    ];
    const weight1 = 10000;
    const rawData1 = [packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.RND.baseTokenAddress,weight1,uniV2PoolAddr)];

    const moreInfo = "0x"
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        tokenConfig.tokens.ETH.baseTokenAddress,
        RND.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

    let rndBalance = await RND.balanceOf(account.address)
    console.log("after ETH Balance: " + await account.getBalance());
    console.log("after RND Balance: " + rndBalance);

    let adapterBalance = await ethers.provider.getBalance(univ2Adapter.address)
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance, 0,"adapter has eth left");
    assert.equal(dexRouterBalance, 0,"dexRouter has eth left");
    assert.equal(rndBalance,462571280772892863273246442,"rnd balance error")

    //to Native
    const fromTokenAmount2 = ethers.utils.parseEther('462571280.772892863273246442');
    const minReturnAmount2 = 0;

    console.log("before ETH Balance: " + await account.getBalance());
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // node1
    const mixAdapter2 = [
        univ2Adapter.address
    ];
    const assertTo2 = [
        uniV2PoolAddr
    ];
    const weight2 = 10000;
    const rawData2 = [packRawData(tokenConfig.tokens.RND.baseTokenAddress,tokenConfig.tokens.WETH.baseTokenAddress,weight2,uniV2PoolAddr)];

    const moreInfo2 = "0x"
    const extraData2 = [moreInfo2];
    const router2 = [mixAdapter2, assertTo2, rawData2, extraData2, RND.address];

    // layer1
    const layer2 = [router2];

    const baseRequest2 = [
        RND.address,
        tokenConfig.tokens.ETH.baseTokenAddress,
        fromTokenAmount2,
        minReturnAmount2,
        deadLine,
    ]
    await RND.connect(account).approve(tokenApprove.address, fromTokenAmount2);
    await dexRouter.connect(account).smartSwap(
        baseRequest2,
        [fromTokenAmount2],
        [layer2],
        pmmReq,
    );
    let rndBalance2 = await RND.balanceOf(account.address)
    console.log("after ETH Balance: " + await account.getBalance());
    console.log("after RND Balance: " + rndBalance2);

    let adapterBalance2 = await ethers.provider.getBalance(univ2Adapter.address)
    let dexRouterBalance2 = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance2, 0,"adapter has eth left");
    assert.equal(dexRouterBalance2, 0,"dexRouter has eth left");
    assert.equal(rndBalance2,0,"rnd balance error")

}

async function main() {
    await executeNative();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

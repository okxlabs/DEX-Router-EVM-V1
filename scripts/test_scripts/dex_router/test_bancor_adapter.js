const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
const {assert} = require("chai");

async function executeWETH2BNT() {
    let pmmReq = []
    await setForkBlockNumber(14429782);

    const accountAddress = "0x49ce02683191fb39490583a7047b280109cab9c1";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BNT.baseTokenAddress
    )

    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();

    const fromTokenAmount = ethers.utils.parseEther('0.4');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const bancorPoolAddr = "0x4c9a2bd661d640da3634a4988a9bd2bc0f18e5a9"; // BNT-WETH Pool
    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before BNT Balance: " + await BNT.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        bancorAdapter.address
    ];
    const assertTo1 = [
        bancorAdapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.BNT.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        bancorPoolAddr.replace("0x", "")  // BNT-WETH Pool
    ];
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            ETH.address,                               // from token address
            BNT.address                                // to token address
        ]
    )
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        WETH.address,
        BNT.address,
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

    console.log("after WETH Balance: " + await WETH.balanceOf(bancorAdapter.address));
    console.log("after BNT Balance: " + await BNT.balanceOf(account.address));
}

async function executeNative() {
    let pmmReq = []
    await setForkBlockNumber(14429782);

    const accountAddress = "0x49ce02683191fb39490583a7047b280109cab9c1";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BNT.baseTokenAddress
    )

    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();

    //From Native
    const fromTokenAmount = ethers.utils.parseEther('0.4');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const bancorPoolAddr = "0x4c9a2bd661d640da3634a4988a9bd2bc0f18e5a9"; // BNT-WETH Pool
    console.log("before ETH Balance: " + await account.getBalance());
    console.log("before BNT Balance: " + await BNT.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        bancorAdapter.address
    ];
    const assertTo1 = [
        bancorAdapter.address
    ];
    const weight1 = 10000;
    const rawData1 = [packRawData(tokenConfig.tokens.ETH.baseTokenAddress,tokenConfig.tokens.BNT.baseTokenAddress,weight1,bancorPoolAddr)];

    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            ETH.address,                               // from token address
            BNT.address                                // to token address
        ]
    )
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,tokenConfig.tokens.WETH.baseTokenAddress];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        tokenConfig.tokens.ETH.baseTokenAddress,
        BNT.address,
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

    let bntBalance = await BNT.balanceOf(account.address);
    console.log("before ETH Balance: " + await account.getBalance());
    console.log("after BNT Balance: " + bntBalance);
    let adapterBalance = await ethers.provider.getBalance(bancorAdapter.address)
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance, 0,"adapter has eth left");
    assert.equal(dexRouterBalance, 0,"dexRouter has eth left");
    assert.equal(bntBalance,485845905449590857665,"bnt balance error")

    // to native
    const fromTokenAmount2 = bntBalance;
    const minReturnAmount2 = 0;
    console.log("before ETH Balance: " + await account.getBalance());
    console.log("before BNT Balance: " + await BNT.balanceOf(account.address));

    // node1
    const mixAdapter2 = [
        bancorAdapter.address
    ];
    const assertTo2 = [
        bancorAdapter.address
    ];
    const weight2 = 10000;
    const rawData2 = [packRawData(tokenConfig.tokens.BNT.baseTokenAddress,tokenConfig.tokens.ETH.baseTokenAddress,weight2,bancorPoolAddr)];

    const moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            BNT.address,
            ETH.address,
        ]
    )
    const extraData2 = [moreInfo2];
    const router2 = [mixAdapter2, assertTo2, rawData2, extraData2,BNT.address];

    // layer1
    // const request1 = [requestParam1];
    const layer2 = [router2];

    const baseRequest2 = [
        BNT.address,
        tokenConfig.tokens.ETH.baseTokenAddress,
        fromTokenAmount2,
        minReturnAmount2,
        deadLine,
    ]
    await BNT.connect(account).approve(tokenApprove.address, fromTokenAmount2);
    await dexRouter.connect(account).smartSwap(
        baseRequest2,
        [fromTokenAmount2],
        [layer2],
        pmmReq
    );

    let bntBalance2 = await BNT.balanceOf(account.address);
    console.log("before ETH Balance: " + await account.getBalance());
    console.log("after BNT Balance: " + bntBalance2);
    let adapterBalance2 = await ethers.provider.getBalance(bancorAdapter.address)
    let dexRouterBalance2 = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance2, 0,"adapter has eth left");
    assert.equal(dexRouterBalance2, 0,"dexRouter has eth left");
    assert.equal(bntBalance2,0,"bnt balance error")

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

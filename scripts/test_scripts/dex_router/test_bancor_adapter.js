const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

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

async function main() {
    await executeWETH2BNT();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

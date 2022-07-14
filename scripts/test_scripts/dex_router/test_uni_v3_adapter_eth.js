const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executeWETH2RND() {
    const pmmReq = []
    await setForkBlockNumber(14480328);

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

    tokenApprove = await ethers.getContractAt(
        "TokenApprove",
        "0xb5eA4cD719D4C73e062D6195b17f703792543904"
    );
    dexRouter = await ethers.getContractAt(
        "DexRouter",
        "0x3b3ae790Df4F312e745D270119c6052904FB6790"
    );

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    const fromTokenAmount = ethers.utils.parseEther('0.27');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const uniV3PoolAddr = "0x96b0837489d046A4f5aA9ac2FC9e086bD14Bac1E"; // RND-WETH Pool
    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        univ3Adapter.address
    ];
    const assertTo1 = [
        univ3Adapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.RND.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        uniV3PoolAddr.replace("0x", "")  // RND-WETH Pool
    ];
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            // "888971540474059905480051",
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    WETH.address,
                    RND.address,
                    10000
                ]
            )
        ]
    )
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

    console.log("after WETH Balance: " + await WETH.balanceOf(univ3Adapter.address));
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

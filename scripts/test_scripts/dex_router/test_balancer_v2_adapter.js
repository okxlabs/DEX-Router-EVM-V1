const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executeWETH2IPAL() {
    let pmmReq = []
    await setForkBlockNumber(14436483);

    const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    IPAL = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.IPAL.baseTokenAddress
    )

    const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault ,WETH.address);
    await balancerV2Adapter.deployed();

    const fromTokenAmount = ethers.utils.parseEther('3.5');
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const balancerV2PoolAddr = balancerVault; // IPAL-WETH Pool
    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before IPAL Balance: " + await IPAL.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        balancerV2Adapter.address
    ];
    const assertTo1 = [
        balancerV2Adapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.IPAL.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        balancerV2PoolAddr.replace("0x", "")  // IPAL-WETH Pool
    ];
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes32"],
        [
            WETH.address,                               // from token address
            IPAL.address,                               // to token address
            "0x54b7d8cbb8057c5990ed5a7a94febee61d6b583700020000000000000000016f"  // pool id
        ]
    )
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        WETH.address,
        IPAL.address,
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

    console.log("after WETH Balance: " + await WETH.balanceOf(balancerV2Adapter.address));
    console.log("after IPAL Balance: " + await IPAL.balanceOf(account.address));
}

async function main() {
    await executeWETH2IPAL();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

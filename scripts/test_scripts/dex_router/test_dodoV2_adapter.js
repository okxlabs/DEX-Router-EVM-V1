const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER } = require("./utils")

tokenConfig = getConfig("eth");

async function deployContract() {
    dodoSellHelper = "0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb"
    DODOV2Adapter = await ethers.getContractFactory("DODOV2Adapter");
    DODOV2Adapter = await DODOV2Adapter.deploy();
    await DODOV2Adapter.deployed();
    return DODOV2Adapter
}

async function executeSellQuote(DODOV2Adapter) {
    const pmmReq = []

    let accountAddress = "0xda8A87b7027A6C235f88fe0Be9e34Afd439570b5";
    let DPSPool = "0x3058EF90929cb8180174D74C507176ccA6835D73"
    await startMockAccount([accountAddress]);
    let account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    // WETH
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    // USDC
    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )

    console.log("Before DAI Balance: ", await DAI.balanceOf(account.address));
    console.log("Before USDT Balance: ", await USDT.balanceOf(account.address));

    let fromTokenAmount = await ethers.utils.parseUnits("10000", 6);

    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let poolAddress = "0x3058EF90929cb8180174D74C507176ccA6835D73";

    let mixAdapter1 = [
        DODOV2Adapter.address
    ];
    let assertTo1 = [
        account.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.USDT.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")
    ];

    let moreInfo = "0x";
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, tokenConfig.tokens.USDT.baseTokenAddress];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        USDT.address,
        DAI.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    let tx1 = await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
    let gasCost2 = await getTransactionCost(tx1);
    console.log(gasCost2);
    let tx = await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    let gasCost = await getTransactionCost(tx);
    console.log(gasCost);

    console.log("after Account DAI  Balance: " + await DAI.balanceOf(account.address));
    console.log("after Account USDT Balance: " + await USDT.balanceOf(account.address));
}


async function main() {
    DODOV2Adapter = await deployContract();
    console.log(" ============= executeSellQuote ===============");
    await executeSellQuote(DODOV2Adapter);
}

const getTransactionCost = async (txResult) => {
    const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
    return ethers.BigNumber.from(cumulativeGasUsed);
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("arbitrum")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executenextUSDC2USDCe() {
    const pmmReq = []
    await setForkNetWorkAndBlockNumber('arbitrum', 107990910);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    USDC_e = await ethers.getContractAt(
        "MockERC20",
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
      )
  
    nextUSDC = await ethers.getContractAt(
        "MockERC20",
        "0x8c556cF37faa0eeDAC7aE665f1Bb0FbD4b2eae36"
      )

    const { dexRouter, tokenApprove } = await initDexRouter();

    NexttokenAdapter = await ethers.getContractFactory("NexttokenAdapter");
    NexttokenAdapter = await NexttokenAdapter.deploy();
    await NexttokenAdapter.deployed();

    await nextUSDC.connect(account).transfer(NexttokenAdapter.address, ethers.utils.parseUnits("0.009", 6));

    const fromTokenAmount = ethers.utils.parseUnits("0.009", 6);
    const minReturnAmount = 0;
    const poolAddr = "0xEE9deC2712cCE65174B561151701Bf54b99C24C8";
    console.log("before nextUSDC Balance: " + await nextUSDC.balanceOf(account.address));
    console.log("before USDC.e Balance: " + await USDC_e.balanceOf(account.address));

    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [fromTokenAmount]
    // ];
    const mixAdapter1 = [
        NexttokenAdapter.address
    ];
    const assertTo1 = [
        poolAddr
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction("0x8c556cF37faa0eeDAC7aE665f1Bb0FbD4b2eae36", "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8") +
        "0000000000000000000" +
        weight1 +
        poolAddr.replace("0x", "")
    ];
    const moreInfo = ethers.utils.solidityPack(["bytes32", "address", "address"],
    [   
        "0x6d9af4a33ed4034765652ab0f44205952bc6d92198d3ef78fe3fb2b078d0941c", 
        "0x8c556cF37faa0eeDAC7aE665f1Bb0FbD4b2eae36", 
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
    ]);
    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, nextUSDC.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        nextUSDC.address,
        USDC_e.address,
        fromTokenAmount,
        minReturnAmount,
        1688531637645,
    ]
    await nextUSDC.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwapByOrderId(
        0,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    let gasCost = await getTransactionCost(rxResult);
    console.log("gasCost: "+gasCost);

    console.log("after nextUSDT Balance: " + await nextUSDC.balanceOf(NexttokenAdapter.address));
    console.log("after USDC.e Balance: " + await USDC_e.balanceOf(account.address));
}

const getTransactionCost = async (txResult) => {
    const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
    return ethers.BigNumber.from(cumulativeGasUsed);
  };

async function main() {
    await executenextUSDC2USDCe();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
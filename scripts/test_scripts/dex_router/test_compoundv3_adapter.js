const { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER } = require("./utils");


async function deployContract() {
    CompoundV3Adapter = await ethers.getContractFactory("CompoundV3Adapter");
    CompoundV3Adapter = await CompoundV3Adapter.deploy();
    await CompoundV3Adapter.deployed();
    return CompoundV3Adapter;

}

async function redeemBase() {
    await setForkNetWorkAndBlockNumber("eth", 18353288);

    pmmReq = [];
    userAddress = "0x5f5ec4F83AcCC5bA176064Dbfa67D6ac74c03af2";
    poolAddress = "0xA17581A9E3356d9A858b789D68B4d866e593aE94";
    startMockAccount([userAddress]);
    signer = await ethers.getSigner(userAddress);

    //  CWETH
    CToken = await ethers.getContractAt(
        "MockERC20",
        "0xA17581A9E3356d9A858b789D68B4d866e593aE94"
    );
    //  WETH
    BaseToken = await ethers.getContractAt(
        "MockERC20",
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    );

    // check user token
    CTokenBalance = await CToken.balanceOf(userAddress);
    console.log("User CToken Balance: ", CTokenBalance.toString());
    BaseTokenBalance = await BaseToken.balanceOf(userAddress);
    console.log("User BaseToken Balance: ", BaseTokenBalance.toString());

    let { dexRouter, tokenApprove } = await initDexRouter();
    CompoundV3Adapter = await deployContract();

    let fromTokenAmount = CTokenBalance;
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [
        CompoundV3Adapter.address
    ];
    let assertTo1 = [
        CompoundV3Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace("0x", "");

    let rawData1 = [
        "0x" +
        direction(CToken.address, BaseToken.address) +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", ""),
    ];

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [CToken.address, BaseToken.address, false]
    );

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, CToken.address];
    let orderId = 0;
    let layer1 = [router1];
    let baseRequest = [
        CToken.address,
        BaseToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ];

    const uint256Max = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    await CToken.connect(signer).approve(tokenApprove.address, uint256Max);
    let tx = await dexRouter.connect(signer).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    CTokenBalance = await CToken.balanceOf(userAddress);
    console.log("After User CToken Balance: ", CTokenBalance.toString());
    BaseTokenBalance = await BaseToken.balanceOf(userAddress);
    console.log("After User BaseToken Balance: ", BaseTokenBalance.toString());


}

async function mintBase() {
    await setForkNetWorkAndBlockNumber("eth", 18353288);

    pmmReq = [];
    userAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";
    poolAddress = "0xA17581A9E3356d9A858b789D68B4d866e593aE94";
    startMockAccount([userAddress]);
    signer = await ethers.getSigner(userAddress);

    //  CWETH
    CToken = await ethers.getContractAt(
        "MockERC20",
        "0xA17581A9E3356d9A858b789D68B4d866e593aE94"
    );
    //  WETH
    BaseToken = await ethers.getContractAt(
        "MockERC20",
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    );

    // check user token
    CTokenBalance = await CToken.balanceOf(userAddress);
    console.log("User CToken Balance: ", CTokenBalance.toString());
    BaseTokenBalance = await BaseToken.balanceOf(userAddress);
    console.log("User BaseToken Balance: ", BaseTokenBalance.toString());


    let { dexRouter, tokenApprove } = await initDexRouter();
    CompoundV3Adapter = await deployContract();

    let fromTokenAmount = BaseTokenBalance;
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [
        CompoundV3Adapter.address
    ];
    let assertTo1 = [
        CompoundV3Adapter.address
    ];
    let weight1 = Number(10000).toString(16).replace("0x", "");

    let rawData1 = [
        "0x" +
        direction(BaseToken.address, CToken.address) +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", ""),
    ];

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [BaseToken.address, CToken.address, true]
    );
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, BaseToken.address];
    let orderId = 0;
    let layer1 = [router1];
    let baseRequest = [
        BaseToken.address,
        CToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ];

    await BaseToken.connect(signer).approve(tokenApprove.address, fromTokenAmount);
    let tx = await dexRouter.connect(signer).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    CTokenBalance = await CToken.balanceOf(userAddress);
    console.log("After User CToken Balance: ", CTokenBalance.toString());
    BaseTokenBalance = await BaseToken.balanceOf(userAddress);
    console.log("After User BaseToken Balance: ", BaseTokenBalance.toString());

}

async function main() {
    console.log("\n===== compoundv3 mintBase =====");
    await mintBase();
    console.log("\n===== compoundv3 redeemBase =====");
    await redeemBase();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });


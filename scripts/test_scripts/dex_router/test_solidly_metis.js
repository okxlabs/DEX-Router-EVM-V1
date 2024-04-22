let { ethers } = require("hardhat");
require("../../tools");
let { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
let { initDexRouter, direction, FOREVER } = require("./utils");

// Trace on chain: https://explorer.metis.io/tx/0x42ddcdb850ac40f2459119274c799cbe5e578294fee6c59489d00732edc5d9cc
async function EthToUsdc() {
    let pmmReq = [];

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" };
    // METIS-USDC
    WETH = await ethers.getContractAt(
        "MockERC20",
        "0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481"
    ) 

    USDC = await ethers.getContractAt(
        "MockERC20",
        "0xEA32A96608495e54156Ae48931A7c20f0dcc1a21"
    ) 

    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const SolidlyAdapter = "0x25831CdD393d9dE24dEAa987A29c640184350F5D";
    let fromTokenAmount =  ethers.utils.parseEther('0.01');
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    let poolAddress = "0x5ab390084812E145b619ECAA8671d39174a1a6d1"; 

    let mixAdapter1 = [
        SolidlyAdapter
    ];
    let assertTo1 = [
        SolidlyAdapter
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');

    moreInfo = "0x";

    let rawData1 = [
        "0x" + 
        "0" +  // 0: sellBase / 8: sellQuote
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "") 
    ];

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        ETH.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

}

// Trace on chain: https://explorer.metis.io/tx/0xf94ef939a4fb3957e6204e269b13b7f1c8697f5d85b8e592bffebd1926ef4400
async function UsdtToEth() {
    let pmmReq = [];

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" };
    // METIS-USDC
    WETH = await ethers.getContractAt(
        "MockERC20",
        "0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481"
    ) 

    USDT = await ethers.getContractAt(
        "MockERC20",
        "0xbB06DCA3AE6887fAbF931640f67cab3e3a16F4dC"
    ) 

    const dexRouter = await ethers.getContractAt("DexRouter", "0x6b2C0c7be2048Daa9b5527982C29f48062B34D58");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x57df6092665eb6058DE53939612413ff4B09114E");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const SolidlyAdapter = "0x25831CdD393d9dE24dEAa987A29c640184350F5D";
    let fromTokenAmount =  ethers.utils.parseUnits('0.1', 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    let poolAddress = "0x75ef3cebdd2b8e42d459cdecad4167be86cfd511"; 

    let mixAdapter1 = [
        SolidlyAdapter
    ];
    let assertTo1 = [
        SolidlyAdapter
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');

    moreInfo = "0x";

    let rawData1 = [
        "0x" + 
        "0" +  // 0: sellBase / 8: sellQuote
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "") 
    ];

    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, USDT.address];
      
    //   // layer1
    // request1 = [requestParam1];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        USDT.address,
        ETH.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await USDT.approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {value: fromTokenAmount}
    );

}

async function main() {
    console.log(" ============= On chain test ===============");
    // await EthToUsdc();
    await UsdtToEth();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
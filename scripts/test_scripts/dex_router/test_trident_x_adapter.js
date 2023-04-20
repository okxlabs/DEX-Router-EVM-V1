const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("op")
//tokenConfig = getConfig("polygon")
//tokenConfig = getConfig("bsc")
//tokenConfig = getConfig("arbitrum")


async function executeWETH2USDC() {
    // test trident in op
    // compare TX in block 89383284
    // https://optimistic.etherscan.io/tx/0x3966b0abd2108feb56eacb4d24c2465c747c926548c8cc29ca4312d0c9f30923
    // test trident in polygon
    // compare TX in block 41479575
    // https://optimistic.etherscan.io/tx/0x3966b0abd2108feb56eacb4d24c2465c747c926548c8cc29ca4312d0c9f30923    
    // test trident in bsc
    // compare TX in block 27315967
    // https://bscscan.com/tx/0x33ddb8688d2a8f58e52b5d8407fd4e0efb7abbd96e24111f64e8396a73e092cb   
    // test trident in arbitrum
    // compare TX in block 79996064
    // https://optimistic.etherscan.io/tx/0x3966b0abd2108feb56eacb4d24c2465c747c926548c8cc29ca4312d0c9f30923


    const pmmReq = []
    await setForkNetWorkAndBlockNumber('op',89383283);
    //await setForkNetWorkAndBlockNumber('polygon',41479574);
    //await setForkNetWorkAndBlockNumber('bsc',27315966);
    //await setForkNetWorkAndBlockNumber('arbitrum',79996063);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
        //tokenConfig.tokens.WBNB.baseTokenAddress
        //tokenConfig.tokens.USDT.baseTokenAddress
    )

    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
        //tokenConfig.tokens.USDT.baseTokenAddress
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.address);//WMATIC、WBNB、

    TridentAdapter = await ethers.getContractFactory("TridentAdapter");
    tridentAdapter = await TridentAdapter.deploy("0xc35DADB65012eC5796536bD9864eD8773aBc74C4");
    //op bentobox address 0xc35DADB65012eC5796536bD9864eD8773aBc74C4
    //polygon bentobox address 0x0319000133d3AdA02600f0875d2cf03D442C3367
    //bsc bentobox address 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966
    //arbitrum bentobox address 0x74c764D41B77DBbb4fe771daB1939B00b146894A
    await tridentAdapter.deployed();

    // approve to  TridentAdapter 
    // op 0.0005 WETH ——> USDC
    const fromTokenAmount = ethers.utils.parseUnits("0.0005", tokenConfig.tokens.WETH.decimals);
    //polygon 1 USDT ——> USDC
    //const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);
    //bsc 0.005 BNB ——> USDT
    //const fromTokenAmount = ethers.utils.parseUnits("0.005", tokenConfig.tokens.WBNB.decimals);
    //arbitrum 1 USDT ——> USDC
    //const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);

    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x7086622E6Db990385B102D79CB1218947fb549a9";
    //op：WETH-USDC 0x7086622E6Db990385B102D79CB1218947fb549a9
    //polyon ：USDC-USDT 0x231BA46173b75E4D7cEa6DCE095A6c1c3E876270
    //bsc：BNB-USDT 0x2f56932cb53d8E292644Da1a62Ed58242B80510e
    //arbitrum：USDT-USDC 0x79bf7147eBCd0d55e83Cb42ed3Ba1bB2Bb23eF20


    // console.log("before Adapter Base Balance: " + await Base.balanceOf(tridentAdapter.address));
    // console.log("before Adpater Quote Balance: " + await Quote.balanceOf(tridentAdapter.address));

    const mixAdapter1 = [
        tridentAdapter.address
    ];
    const assertTo1 = [
        tridentAdapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        "0" +
        direction(Base.address, Quote.address) +
        weight1 +
        poolAddress.replace("0x", "")  
    ];

    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [Base.address, accountAddress, true]
    )

    const extraData1 = [moreInfo];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, Base.address];

    // layer1
    const layer1 = [router1];
    const orderId = 0;

    const baseRequest = [
        Base.address,
        Quote.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await Base.connect(account).approve(tokenApprove.address, fromTokenAmount);
   
    tx = await dexRouter.connect(account).smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    //console.log(tx);
    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
}



async function main() {
    await executeWETH2USDC();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

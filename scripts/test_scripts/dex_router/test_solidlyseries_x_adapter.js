const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
tokenConfig = getConfig("ftm")
// tokenConfig = getConfig("bsc");
// tokenConfig = getConfig("polygon");
// tokenConfig = getConfig("op");
// tokenConfig = getConfig("arbitrum");

async function executeBase2Quote() {
    const pmmReq = []
    // Network fantom
    await setForkNetWorkAndBlockNumber('fantom',59053927);
    // Network bsc
    // await setForkNetWorkAndBlockNumber('bsc',27449190);
    // Network polygon
    // await setForkNetWorkAndBlockNumber('polygon',41663535);
    // Network optimism
    // await setForkNetWorkAndBlockNumber('op',91810906);
    // Network arbitrum (Rames Exchanges )
    // await setForkNetWorkAndBlockNumber('arbitrum',81682360);
    // Network arbitrum (solidlizard)
    // await setForkNetWorkAndBlockNumber('arbitrum',81683387);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WFTM.baseTokenAddress
        //tokenConfig.tokens.USDT.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
        //tokenConfig.tokens.USDC.baseTokenAddress
    )

    console.log("before Account Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Account Quote Balance: " + await Quote.balanceOf(account.address));    

    let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WFTM.baseTokenAddress);
    //let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WBNB.baseTokenAddress);
    //let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WMATIC.baseTokenAddress);
    //let { dexRouter, tokenApprove } = await initDexRouter(tokenConfig.tokens.WETH.baseTokenAddress);//op and arb

    SolidlyseriesAdapter = await ethers.getContractFactory("SolidlyseriesAdapter");
    solidlyseriesAdapter = await SolidlyseriesAdapter.deploy();
    await solidlyseriesAdapter.deployed();

    // transfer 1 WFTM to Pool
     const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.WFTM.decimals);
    // transfer 1 USDT to Pool
    // const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const poolAddress = "0x1c8dd14e77C20eB712Dc30bBf687a282CFf904a2";//spiritswapv2（ftm）WFTM-DAI 1WFTM
    //const poolAddress = "0x68ddA7c12f792E17C747A627d41153c103310D74";//cone（bsc）USDT-USDC 1USDT
    //const poolAddress = "0x4570da74232c1A784E77c2a260F85cdDA8e7d47B";//Dystopia（poly）USDC-USDT 1USDT so selling usdt need to use sellquote-rawData choose 8
    //const poolAddress = "0x7cabA4D27098bdaabB545e21CA5d865519492a25";//Velodrome（op）USDC-USDT 1USDT so selling usdt need to use sellquote-rawData choose 8
    //const poolAddress = "0xe25c248Ee2D3D5B428F1388659964446b4d78599";//Rames Exchanges（arb）USDT-USDC 1USDT
    //const poolAddress = "0xd7921c1d058FBac04dbf242f7c70Ce5F316E387a";//solidlizard（arb）USDT-USDC 1USDT


    // console.log("before Base Balance: " + await Base.balanceOf(account.address));
    // console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

    const mixAdapter1 = [
        solidlyseriesAdapter.address
    ];
    const assertTo1 = [
        poolAddress
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        "0" +                          // 0/8
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")  //  Pool
    ];
    const moreInfo = "0x"
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

// Compare TX：spiritswap v2
// https://ftmscan.com/tx/0x8c4527a5fa23e11bdc6440b3e8d958cf87d71a41654255c147b272bc75d1d624
// In actual transactions, the router will deduct additional handling fees, so the actual transaction balance will be slightly lower
// swapper will get 193309440/1e18 dai

// Compare TX：cone
// https://bscscan.com/tx/0xd1516097493ff8852fa2babe2a1c3f713d154f39d4496c21591f5edf0a3e9a41
// Compare TX：Dystopia
// https://polygonscan.com/tx/0xeb4f64e489a71f749b95111f30fdedc2c279224808ca9e238dad3943f5b763fb
// Compare TX：Velodrome
// https://optimistic.etherscan.io/tx/0xd0f9c1e2ef8a0fbb48f70ce8c2dfd3dd37dc0ab291e303291282a426b5723d67
// Compare TX：Rames Exchanges
// https://arbiscan.io/tx/0x0c1d86cfa6dc1136f9a837179b1ec33800b81c3ce03e13ba74d90262998992a3
// Compare TX：solidlizard
// https://arbiscan.io/tx/0xd62e9495b7754895d7bf4e4753110c466eab72acb5c3c52b142bb768b2a1dbfc
async function main() {
    await executeBase2Quote();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

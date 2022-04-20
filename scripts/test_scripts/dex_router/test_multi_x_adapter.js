const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

//curveV1/curveV2/balancerV1/kyber
async function initAdapter(adapterList){
    const AdapterList = new Map()
    for await(var key of adapterList){
        switch(key){
            case "curveV1":
                AdapterContractName = "CurveAdapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy();
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
            case "curveV2":
                AdapterContractName = "CurveV2Adapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
            case "balancerV1":
                AdapterContractName = "BalancerAdapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy();
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
            case "kyber":
                AdapterContractName = "KyberAdapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy();
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
        }  
        AdapterList.set(key, tempAdapter)
    }
    AdapterList["curveV1"];
    return AdapterList;

}


async function wrapInfo(from, to, amountIn, layerList){
    let FromToken = from;
    let ToToken = to;
    let fromTokenAmountTotal = 0;
    let minReturnAmount = 0;
    let deadLine = FOREVER;

    let baseRequest = [];
    let fromTokenAmount = [];
    let layer = [];
    let pmmInfo = [];

    for await(var layerInfo of layerList){
        let layerAmount = layerInfo[0] * amountIn / 10000;
        let routerList = layerInfo[1];
        let router = [];
        fromTokenAmountTotal += layerAmount;
        layerAmount = ethers.utils.parseUnits(layerAmount + "", await FromToken.decimals())
        fromTokenAmount.push(layerAmount);
        for await(var adapterList of routerList){
            let mixAdapter = [];
            let mixAssertTo = [];
            let mixRawData = [];
            let mixExtraData = [];
            let fromTokenAddressStr = 0;
            for await(var adapterInfo of adapterList){
                let adapterName = adapterInfo[0];
                let ratio = adapterInfo[1];
                let token1 = adapterInfo[2];
                let token2 = adapterInfo[3];
                let poolAddr = adapterInfo[4];
                let assertTo = (adapterInfo[5] == "" ? adapter.get(adapterName).address:adapterInfo[5]);
                let moreInfo = adapterInfo[6];
                mixAdapter.push(adapter.get(adapterName).address)
                mixAssertTo.push(assertTo) 

                mixRawData.push("0x" + direction(token1.baseTokenAddress, token2.baseTokenAddress) + "0000000000000000000" + Number(ratio).toString(16).replace('0x', '') + poolAddr.replace("0x", ""))
                mixExtraData.push(moreInfo)
                fromTokenAddressStr = token1.baseTokenAddress + "";
            }
            _router = [mixAdapter, mixAssertTo, mixRawData, mixExtraData, fromTokenAddressStr];
            router.push(_router);
            
        }
        layer.push(router);
    }

    baseRequest = [
        FromToken.address,
        ToToken.address,
        ethers.utils.parseUnits(fromTokenAmountTotal + "", await FromToken.decimals()),
        minReturnAmount,
        deadLine,
    ]

    return {baseRequest, fromTokenAmount, layer, pmmInfo}
}

async function executeMutilXAdapter(account, blockNumber, from, to, amountIn, layerInfo) {

    
    await setForkBlockNumber(blockNumber);
    const accountAddress = account;
    await startMockAccount([accountAddress]);
    account = await ethers.getSigner(accountAddress);
    adapterList = ["curveV1", "curveV2", "balancerV1", "kyber"];

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    FromToken = await ethers.getContractAt(
        "MockERC20",
        from.baseTokenAddress
    )
    ToToken = await ethers.getContractAt(
        "MockERC20",
        to.baseTokenAddress
    )

    console.log("before " + from.name + " Balance: " + await FromToken.balanceOf(account.address));
    console.log("before " + to.name + "  Balance: " + await ToToken.balanceOf(account.address));

    let { dexRouter, tokenApprove } = await initDexRouter();
    adapter = await initAdapter(adapterList);
    
    let {baseRequest, fromTokenAmount, layer, pmmInfo} = await wrapInfo(FromToken, ToToken, amountIn, layerInfo);

    // console.log("baseRequest",baseRequest)
    // console.log("fromTokenAmount", fromTokenAmount)
    // console.log("layer", layer[0])
    // console.log("pmmInfo", pmmInfo)

    await FromToken.connect(account).approve(tokenApprove.address, baseRequest[2]);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        fromTokenAmount,
        layer,
        pmmInfo,
    );

    console.log("after " + from.name + " Balance: " + await FromToken.balanceOf(account.address));
    console.log("after " + to.name + "  Balance: " + await ToToken.balanceOf(account.address));
}

async function main() {

    const curveV1USDTDAIPoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
    const banlancerV1AAVEWETHPoolAddress = "0xc697051d1c6296c24ae3bcef39aca743861d9a81";
    const curveV2USDTWETHPoolAddress = "0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5";
    const kyberUSDTWETHPoolAddress = "0xcE9874C42DcE7fffbE5E48B026Ff1182733266Cb";
    const kyberUSDCUSDTPoolAddress = "0x306121f1344ac5F84760998484c0176d7BFB7134";
    const curveV1USDCUSDTPoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
    
    const AssertToSelf = "";

    
    //case0 6000 USDT -> DAI CurveV1:100%
    {        
        console.log("\n===========(case0 6000 USDT -> DAI CurveV1:100%)===========")

        var account = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.USDT
        var toToken = tokenConfig.tokens.DAI
        var amountIn = 6000

        var curveV1USTToDAIMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [fromToken.baseTokenAddress,toToken.baseTokenAddress,2,0,false]
        )

        var router1 = [
            ["curveV1", 10000, tokenConfig.tokens.USDT, tokenConfig.tokens.DAI, curveV1USDTDAIPoolAddress, AssertToSelf, curveV1USTToDAIMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
    }
    //case1 3.5 WETH -> AAVE BalancerV1:100%
    {
        console.log("\n===========(case1 3.5 AAVE -> WETH BalancerV1:100%)===========")
        var account = "0x260edfea92898a3c918a80212e937e6033f8489e"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.AAVE
        var amountIn = 3.5

        var banlancerV1AAVEToWETHMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress                                // to token address
            ]
        )

        var router1 = [
            ["balancerV1", 10000, tokenConfig.tokens.WETH, tokenConfig.tokens.AAVE, banlancerV1AAVEWETHPoolAddress, AssertToSelf, banlancerV1AAVEToWETHMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
    }
    //case2 500 USDT -> WETH CurveV2:100%
    {
        console.log("\n===========(case2 500 USDT -> WETH CurveV2:100%)===========")
        var account = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.USDT
        var toToken = tokenConfig.tokens.WETH
        var amountIn = 500


        var curveV2MoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128"],
            [
                fromToken.baseTokenAddress,
                toToken.baseTokenAddress,
                0,
                2
            ]
        )


        var router1 = [
            ["curveV2", 10000, tokenConfig.tokens.USDT, tokenConfig.tokens.WETH, curveV2USDTWETHPoolAddress, AssertToSelf, curveV2MoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);

    }
    // case3 500 USDT -> WETH Kyber:100%
    {
        console.log("\n===========(case3 500 USDT -> WETH Kyber:100%)===========")
        var account = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.USDT
        var toToken = tokenConfig.tokens.WETH
        var amountIn = 500
        

        var kyberMoreInfo = "0x"

        var router1 = [
            ["kyber", 10000, tokenConfig.tokens.USDT, tokenConfig.tokens.WETH, kyberUSDTWETHPoolAddress, kyberUSDTWETHPoolAddress, kyberMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
    }
    //case21 0.5 WETH -> USDT Kyber:50%
    //                -> USDT CurveV2:50%
    {
        console.log("\n===========(case21 1 WETH -> USDT Kyber:50%/CurveV2:50%)===========")
        var account = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.USDT
        var amountIn = 1

        var kyberMoreInfo = "0x";

        var curveV2MoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128"],
            [
                fromToken.baseTokenAddress,
                toToken.baseTokenAddress,
                2,
                0
            ]
        )

        var router1 = [
            ["kyber", 5000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDT, kyberUSDTWETHPoolAddress, kyberUSDTWETHPoolAddress, kyberMoreInfo],
            ["curveV2", 5000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDT, curveV2USDTWETHPoolAddress, AssertToSelf, curveV2MoreInfo]
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);

    }
    //case22 500 USDT -> USDC Kyber:50%
    //                -> USDC CurveV1:50%
    {
        console.log("\n===========(case22 500 USDT -> USDC Kyber:50%/CurveV1:50%)===========")
        var account = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.USDT
        var toToken = tokenConfig.tokens.USDC
        var amountIn = 500

        var kyberMoreInfo = "0x"

        var curveV1MoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [
                fromToken.baseTokenAddress,
                toToken.baseTokenAddress,
                2,
                1,
                false
            ]
        )

        var router1 = [
            ["kyber", 5000, tokenConfig.tokens.USDT, tokenConfig.tokens.USDC, kyberUSDCUSDTPoolAddress, kyberUSDTWETHPoolAddress, kyberMoreInfo],
            ["curveV1", 5000, tokenConfig.tokens.USDT, tokenConfig.tokens.USDC, curveV1USDCUSDTPoolAddress, AssertToSelf, curveV1MoreInfo]
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);

    }
    //case31 无有效兑换交易对
    {
        console.log("\n===========(case31 无有效兑换交易对)===========")
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

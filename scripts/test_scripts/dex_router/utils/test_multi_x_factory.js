const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, packRawData, FOREVER } = require("./")

// valutPoolAddress
// curveV1
curveV1USDTDAIPoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
curveV1USDCUSDTPoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
// curveV2
curveV2USDTWETHPoolAddress = "0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5";
// balancerV1
banlancerV1AAVEWETHPoolAddress = "0xc697051d1c6296c24ae3bcef39aca743861d9a81";
// balancerV2
balancerV2VaultAddress = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";
balancerV2WETHIPALPoolId = "0x54b7d8cbb8057c5990ed5a7a94febee61d6b583700020000000000000000016f";
balancerV2WETHUSDCPoolId = "0x96646936B91D6B9D7D0C47C496AFBF3D6EC7B6F8000200000000000000000019";
balancerV2USDCBREEDpoolId = "0x112254b3bb8aabfe475497f2ff5be9ffbbc684d10002000000000000000001c7";
// kyber
kyberUSDTWETHPoolAddress = "0xcE9874C42DcE7fffbE5E48B026Ff1182733266Cb";
kyberUSDCUSDTPoolAddress = "0x306121f1344ac5F84760998484c0176d7BFB7134";
// uniV2
uniV2USDCWETHPoolAddr = "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc"; // USDC-WETH Pool
// uniV3
uniV3USDCWETHPoolAddr = "0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8"; // USDC-WETH V3 0.3% Pool
// bancor
bancorBNTUSDCPoolAddr = "0x23d1b2755d6C243DFa9Dd06624f1686b9c9E13EB";
bancorETHBNTPoolAddr = "0x4c9a2bd661d640da3634a4988a9bd2bc0f18e5a9";

// assertToAddress
AssertToSelf = "";

//init Adapter
initAdapter = async function (adapterList){
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
            case "balancerV2":
                AdapterContractName = "BalancerV2Adapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy(balancerV2VaultAddress, tokenConfig.tokens.WETH.baseTokenAddress);
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
            case "uniV2":
                AdapterContractName = "UniAdapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy();
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
            case "uniV3":
                AdapterContractName = "UniV3Adapter";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
            case "bancor":
                AdapterContractName = "BancorAdapter";
                const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";
                tempAdapter = await ethers.getContractFactory(AdapterContractName);
                tempAdapter = await tempAdapter.deploy(BancorNetwork, tokenConfig.tokens.WETH.baseTokenAddress);
                await tempAdapter.deployed();
                console.log(key + " : " + tempAdapter.address)
                break;
        }  
        AdapterList.set(key, tempAdapter)
    }
    return AdapterList;

}

// wrapInfo: return baseRequest, fromTokenAmount, layer, pmmInfo
wrapInfo = async function (from, to, amountIn, layerList){
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
                mixRawData.push(packRawData(token1.baseTokenAddress, token2.baseTokenAddress, ratio, poolAddr))
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

// execute testcase
executeMutilXAdapter = async function (account, blockNumber, from, to, amountIn, layerList, isFromETH = false, isToETH = false) {

    await setForkBlockNumber(blockNumber);
    const accountAddress = account;
    const accountGasRecoverAddress = "0xcBfd32FDec86F88784266221CcE8141dA7B9A9eD";
    await startMockAccount([accountAddress]);
    await startMockAccount([accountGasRecoverAddress]);
    account = await ethers.getSigner(accountAddress);
    accountGasRecover = await ethers.getSigner(accountGasRecoverAddress);
    assert(accountGasRecoverAddress != accountAddress, "executeMutilXAdapter : accountGasRecoverAddress == accountAddress")

    // set account balance 2.0 eth for gas
    await setBalance(accountAddress, "0x1158e460913d00000");
    await setBalance(accountGasRecoverAddress, "0x1158e460913d00000");

    FromToken = await ethers.getContractAt(
        "MockERC20",
        from.baseTokenAddress
    )
    ToToken = await ethers.getContractAt(
        "MockERC20",
        to.baseTokenAddress
    )

    var adapterList = []
    for (var layerInfo of layerList){
        for (var AdapterList of layerInfo[1]){
            for (var adapterInfo of AdapterList){
                let adapterName = adapterInfo[0];
                adapterList.push(adapterName)
            }    
        }
    }
    var adapterList = [...new Set(adapterList)]

    let { dexRouter, tokenApprove } = await initDexRouter();
    adapter = await initAdapter(adapterList);
    
    let {baseRequest, fromTokenAmount, layer, pmmInfo} = await wrapInfo(FromToken, ToToken, amountIn, layerList);

    // console.log("baseRequest",baseRequest)
    // console.log("fromTokenAmount", fromTokenAmount)
    // console.log("layer", layer[0])
    // console.log("pmmInfo", pmmInfo)

    let fromTokenBefore = await FromToken.balanceOf(account.address);
    let toTokenBefore = await ToToken.balanceOf(account.address);
    console.log("fromTokenBefore : ", fromTokenBefore)

    let valueInfo = {}

    if (isFromETH){
        from = tokenConfig.tokens.ETH
        baseRequest[0] = from.baseTokenAddress
        fromTokenBefore = await ethers.provider.getBalance(account.address)
        valueInfo = {value: ethers.utils.parseUnits(amountIn + "", from.decimals)}
    } 
    else if(isToETH) {
        to = tokenConfig.tokens.ETH
        baseRequest[1] = to.baseTokenAddress
        toTokenBefore = await ethers.provider.getBalance(account.address)
        let approveResult = await FromToken.connect(account).approve(tokenApprove.address, baseRequest[2]);
        // return gasCost
        let gasCost = await getTransactionCost(approveResult)
        // console.log("gasCost:", gasCost)
        await accountGasRecover.sendTransaction({value: gasCost, to: account.address})
    } 
    else {
        let approveResult = await FromToken.connect(account).approve(tokenApprove.address, baseRequest[2]);
        // return gasCost
        let gasCost = await getTransactionCost(approveResult)
        // console.log("gasCost:", gasCost)
        await accountGasRecover.sendTransaction({value: gasCost, to: account.address})
    }

    
    let dexRouterResult = await dexRouter.connect(account).smartSwap(
        baseRequest,
        fromTokenAmount,
        layer,
        pmmInfo,
        valueInfo
    );

    let gasCost = await getTransactionCost(dexRouterResult)
    // console.log("gasCost:", gasCost)
    await accountGasRecover.sendTransaction({value: gasCost, to: account.address})


    let fromTokenAfter = await FromToken.balanceOf(account.address);
    let toTokenAfter = await ToToken.balanceOf(account.address);

    if (isFromETH){
        fromTokenAfter = await ethers.provider.getBalance(account.address)
    } 
    else if(isToETH) {
        toTokenAfter = await ethers.provider.getBalance(account.address)
    } 

    let diffFrom = fromTokenAfter.sub(fromTokenBefore)
    let diffTo = toTokenAfter.sub(toTokenBefore)


    console.log(adapterList)
    console.log("%s changed: %s >>>>(%s)>>>> %s", from.name, fromTokenBefore.toString(), diffFrom.toString(), fromTokenAfter.toString());
    assert((fromTokenBefore.sub(fromTokenAfter)).eq(ethers.utils.parseUnits(amountIn + "", await from.decimals)), "fromToken changed notequal Amount : " + (fromTokenAfter.sub(fromTokenBefore)).toString() + " != " + fromTokenAmount.toString())
    console.log("%s changed: %s >>>>(%s)>>>> %s", to.name, toTokenBefore.toString(), diffTo.toString(), toTokenAfter.toString());
    for await(var key of adapterList){
        let retention = await FromToken.balanceOf(adapter.get(key).address)
        assert(retention == 0, key + " : Adapter retention > 0!")
        console.log(key + "Adapter retention Balance: " + retention.toString());
    }
}

const getTransactionCost = async (txResult) => {
    const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
    return ethers.BigNumber.from(txResult.gasPrice).mul(ethers.BigNumber.from(cumulativeGasUsed));
  };

module.exports = {
    executeMutilXAdapter,
    curveV1USDTDAIPoolAddress,
    curveV1USDCUSDTPoolAddress,
    curveV2USDTWETHPoolAddress,
    banlancerV1AAVEWETHPoolAddress,
    balancerV2WETHIPALPoolId,
    balancerV2WETHUSDCPoolId,
    balancerV2USDCBREEDpoolId,
    kyberUSDTWETHPoolAddress,
    kyberUSDCUSDTPoolAddress,
    uniV2USDCWETHPoolAddr,
    uniV3USDCWETHPoolAddr,
    bancorBNTUSDCPoolAddr,
    bancorETHBNTPoolAddr,
    AssertToSelf,
  }

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
const axios = require("axios")


const {assert} = require("chai");
const EXCHANGE_PROXY = "0xdef1c0ded9bec7f1a1670819833240f027b25eff"

async function getZeroExAdapter() {
    ZeroExAdapter = await ethers.getContractFactory("ZeroExAdapter");
    ZeroExAdapter = await ZeroExAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await ZeroExAdapter.deployed();    
    return ZeroExAdapter
}

const instance = axios.create({
    baseURL: 'https://api.0x.org'
  });
  
async function getOrders(baseToken, quoteToken) {
    let result
    let metadata
    await instance.get('/orderbook/v1', {
        params: {
            "baseToken": baseToken,
            "quoteToken": quoteToken
        }
    }).then(function (response) { 
        response.data.bids.records.forEach(order => {
            if (order.metaData.remainingFillableTakerAmount != "0") {
                result = order;
                metadata = order.metaData
            }
        });
    })
    return {
        "result": result, 
        "metadata": metadata
    }
}
    


async function getMoreInfo(fromToken, toToken, order, signature) {  
    console.log(order)
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", 
            "tuple(address, address, uint128, uint128, uint128, address, address, address, address, bytes32, uint64, uint256)", 
            "tuple(uint8, uint8, bytes32, bytes32)"
        ],
        [
            fromToken,
            toToken,
            [
                order.makerToken, 
                order.takerToken,
                order.makerAmount,
                order.takerAmount,
                order.takerTokenFeeAmount,
                order.maker,
                order.taker,
                order.sender, 
                order.feeRecipient,
                order.pool,
                order.expiry,
                order.salt
            ],
            [
                signature.signatureType,
                signature.v,
                signature.r,
                signature.s
            ]
        ] 
    )
    return moreInfo
}


userAddress = "0xBDa23B750dD04F792ad365B5F2a6F1d8593796f2"
const fromTokenAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
const toTokenAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
let fromTokenAmount 
const pool = EXCHANGE_PROXY

async function prepare(ZeroExAdapter) {
    
    startMockAccount([userAddress]);
    await setBalance(userAddress, "0x53444835ec580000");

    signer = await ethers.getSigner(userAddress);
    
    fromToken = await ethers.getContractAt(
        "MockERC20",
        fromTokenAddress
    )
      
    // to Token
    toToken = await ethers.getContractAt(
        "MockERC20",
        toTokenAddress
    )
    
    _result = await getOrders(fromTokenAddress, toTokenAddress)
    
    let rawOrder = _result["result"]
    let metadata = _result["metadata"]

    console.log(rawOrder)
    console.log(metadata)

    // fromTokenAmount = ethers.utils.parseUnits("26", 6)
    fromTokenAmount = metadata.remainingFillableTakerAmount
    
    console.log(fromTokenAmount)

    // prepare order
    const signature = rawOrder.order.signature

    const moreInfo = await getMoreInfo(fromTokenAddress, toTokenAddress, rawOrder.order, signature)
    
    return moreInfo
}

async function exchange(ZeroExAdapter, moreInfo) {


    console.log("fromToken BeforeBalance: ",await fromToken.balanceOf(signer.address));
    console.log("toToken BeforeBalance: ",await toToken.balanceOf(signer.address));
    let { dexRouter, tokenApprove } = await initDexRouter();

    let pmmReq = []
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [
        ZeroExAdapter.address
    ];
    let assertTo1 = [
        ZeroExAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        EXCHANGE_PROXY.replace("0x", "")  
    ];
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];
    let layer1 = [router1];
    let permit = []
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await fromToken.connect(signer).approve(tokenApprove.address, fromTokenAmount)
    await dexRouter.connect(signer).smartSwapWithPermit(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        permit

    );

    console.log("fromToken afterBalance: ",await fromToken.balanceOf(signer.address));
    console.log("toToken afterBalance: ",await toToken.balanceOf(signer.address));

    console.log("success")
}

async function main() {
    const ZeroExAdapter = await getZeroExAdapter()
    const moreInfo  = await prepare(ZeroExAdapter)
    console.log(moreInfo)

    await exchange(ZeroExAdapter, moreInfo)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

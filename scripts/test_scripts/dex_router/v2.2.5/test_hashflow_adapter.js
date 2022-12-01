const { ethers } = require("hardhat");
require("../../../tools");
const axios = require("axios")
const { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");
require('dotenv').config();
let { initDexRouter, direction, FOREVER } = require("../utils")


const _HashFlowRouter = "0xF6a94dfD0E6ea9ddFdFfE4762Ad4236576136613"

async function deployContract() {
    HashFlowAdapter = await ethers.getContractFactory("HashflowAdapter");
    hashFlowAdapter = await upgrades.deployProxy(
      HashFlowAdapter, [_HashFlowRouter, tokenConfig.tokens.WETH.baseTokenAddress]
    );
    await hashFlowAdapter.deployed();

    console.log(hashFlowAdapter.owner());

    return hashFlowAdapter
}

const instance = axios.create({
    baseURL: 'https://api.hashflow.com'
  });
  
// Alter defaults after instance has been created
instance.defaults.headers.common['Authorization'] = process.env.HASHFLOW_AUTH;

async function getMarketMakers() {
  let mm = []
  await instance.get('/taker/v1/marketMakers', {
    params: {
        "source": "okxswap",
        "networkId": 1
     }
  }).then(function (response) {
    console.log(response.data)
    mm = response.data.marketMakers
  })
  return mm
}

async function getMoreInfo(User, HashflowAdapter, fromToken, toToken, fromAmount ) {

    if (fromToken.address == tokenConfig.tokens.ETH.baseTokenAddress) {
        fromToken_address = "0x0000000000000000000000000000000000000000"
    } else {
      fromToken_address = fromToken.address
    }

    if (toToken.address == tokenConfig.tokens.ETH.baseTokenAddress) {
      toToken_address = "0x0000000000000000000000000000000000000000"
    } else {
      toToken_address = toToken.address
    }

    // get mm
    mm = await getMarketMakers()

    let request = {
      "networkId":1,
      "source":"okxswap",
      "rfqType":0,
      "baseToken": fromToken_address,
      "baseTokenAmount": fromAmount.toString(),
      "quoteToken": toToken_address,
      "trader": HashflowAdapter.address,
      "marketMakers": mm
    }

    console.log(request)

    let result = await instance.post('/taker/v2/rfq', request)

 
    result = result.data
    console.log("Hashflow Adapter Address >>> ", HashflowAdapter.address)
    console.log("User Address >>> ", User.address)
    console.log(result)

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      [ "address", "address",  "tuple(address, address, address, address, address, address, uint256, uint256, uint256, uint256, uint256, bytes32, bytes)"]  ,
      [
          fromToken.address,
          toToken.address,
          [
            result["quoteData"].pool,
            result["quoteData"].eoa ? result["quoteData"].eoa: "0x0000000000000000000000000000000000000000",
            result["quoteData"].trader,
            result["quoteData"].trader,
            result["quoteData"].baseToken,
            result["quoteData"].quoteToken,
            result["quoteData"].baseTokenAmount,          // result["quoteData"].effectiveBaseTokenAmount,
            result["quoteData"].baseTokenAmount,          // result["quoteData"].maxBaseTokenAmount,
            result["quoteData"].quoteTokenAmount,
            result["quoteData"].quoteExpiry,
            result["quoteData"].nonce,
            result["quoteData"].txid,
            result["signature"]
          ]
      ]
    )


    return {
      "moreinfo": moreinfo, 
      "pool": result["quoteData"].pool
    }
}

async function ETH2USDT(HashflowAdapter) {
    // signer = await ethers.getSigner();
    userAddress = "0x6a3528677e598b47952749b08469ce806c2524e7"

    startMockAccount([userAddress]);
    await setBalance(userAddress, "0x53444835ec580000");

    signer = await ethers.getSigner(userAddress);

    // from Token

    WETH = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress
    )

    fromToken = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.ETH.baseTokenAddress
    )
    
    // to Token
    toToken = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    let { dexRouter, tokenApprove } = await initDexRouter();
    
    fromAmount = ethers.utils.parseEther("2", 18)
  
    _result = await getMoreInfo(signer, HashflowAdapter, fromToken, toToken, fromAmount )
    moreInfo = _result["moreinfo"]
    poolAddress =  _result["pool"]
    console.log(poolAddress)
     
    // swap
    beforeBalance = await WETH.balanceOf(signer.address);
    console.log("WETH beforeBalance: ", beforeBalance.toString());

    let pmmReq = []
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [
        HashflowAdapter.address
    ];
    let assertTo1 = [
        HashflowAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.USDT.baseTokenAddress) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")  // three pools
    ];
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];
    let layer1 = [router1];

    let baseRequest = [
        tokenConfig.tokens.ETH.baseTokenAddress,
        tokenConfig.tokens.USDT.baseTokenAddress,
        fromAmount,
        minReturnAmount,
        deadLine,
    ]

    await dexRouter.connect(signer).smartSwap(
        baseRequest,
        [fromAmount],
        [layer1],
        pmmReq, {
            value: fromAmount
        }
    );

    
    console.log("fromToken afterBalance: ",await WETH.balanceOf(signer.address));
    console.log("toToken afterBalance: ",await toToken.balanceOf(signer.address));
}


async function main() {

    HashflowAdapter = await deployContract();
    console.log("===== ETH2USDT =====")
    await ETH2USDT(HashflowAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
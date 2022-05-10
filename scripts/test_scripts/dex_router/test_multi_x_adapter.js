const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, packRawData, FOREVER } = require("./utils")
require("./utils/test_multi_x_factory");

async function main() {

    //6000 USDT -> DAI CurveV1:100%
    try {      
        console.log("\n===========(6000 USDT -> DAI CurveV1:100%)===========")

        var account = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.USDT
        var toToken = tokenConfig.tokens.DAI
        var amountIn = 6000

        var curveV1USDToDAIMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [fromToken.baseTokenAddress,toToken.baseTokenAddress,2,0,false]
        )

        var router1 = [
            ["curveV1", 10000, tokenConfig.tokens.USDT, tokenConfig.tokens.DAI, curveV1USDTDAIPoolAddress, AssertToSelf, curveV1USDToDAIMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
    } catch (error) {
        console.log(error)
    }

    //3.5 WETH -> AAVE BalancerV1:100%
    try {
        console.log("\n===========(3.5 WETH -> AAVE BalancerV1:100%)===========")
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
        
    } catch (error) {
        console.log(error)
    }
    //3.5 ETH -> AAVE BalancerV1:100%
    try {
        console.log("\n===========(3.5 ETH -> AAVE BalancerV1:100%)===========")
        var account = "0x260edfea92898a3c918a80212e937e6033f8489e"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.AAVE
        var amountIn = 3.5

        var banlancerV1WETHToAAVEMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress                                // to token address
            ]
        )

        var router1 = [
            ["balancerV1", 10000, tokenConfig.tokens.WETH, tokenConfig.tokens.AAVE, banlancerV1AAVEWETHPoolAddress, AssertToSelf, banlancerV1WETHToAAVEMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];
        var isFromETH = true;
        var isToETH = false;

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);
        
    } catch (error) {
        console.log(error)
    }
    //3.5 AAVE -> ETH BalancerV1:100%
    try {
        console.log("\n===========(3.5 AAVE -> ETH BalancerV1:100%)===========")
        var account = "0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9"
        var blockNumber = 14659813
        var fromToken = tokenConfig.tokens.AAVE
        var toToken = tokenConfig.tokens.WETH
        var amountIn = 3.5

        var banlancerV1WETHToAAVEMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress                                // to token address
            ]
        )

        var router1 = [
            ["balancerV1", 10000, tokenConfig.tokens.AAVE, tokenConfig.tokens.WETH, banlancerV1AAVEWETHPoolAddress, AssertToSelf, banlancerV1WETHToAAVEMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];
        var isFromETH = false;
        var isToETH = true;

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);
        
    } catch (error) {
        console.log(error)
    }
    //260 USDC -> BREED BalancerV2:100%
    try {
        console.log("\n===========(260 USDC -> BREED BalancerV2:100%)===========")
        var account = "0xd6745ac84d8d583c82afb267a52baeacbbf0a3e2"
        var blockNumber = 14665472 
        var fromToken = tokenConfig.tokens.USDC
        var toToken = tokenConfig.tokens.BREED
        var amountIn = 260

        var balancerV2USDCToBREEDMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "bytes32"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress,                                // to token address
                balancerV2USDCBREEDpoolId
            ]
        )

        var router1 = [
            ["balancerV2", 10000, tokenConfig.tokens.USDC, tokenConfig.tokens.BREED, balancerV2VaultAddress, AssertToSelf, balancerV2USDCToBREEDMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);

    } catch (error) {
        console.log(error)
    }
    //3.5 ETH -> IPAL BalancerV2:100%
    try {
        console.log("\n===========(3.5 ETH -> IPAL BalancerV2:100%)===========")
        var account = "0x260edfea92898a3c918a80212e937e6033f8489e"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.IPAL
        var amountIn = 3.5

        var balancerV2WETHToIPALMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "bytes32"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress,                                // to token address
                balancerV2WETHIPALPoolId
            ]
        )

        var router1 = [
            ["balancerV2", 10000, tokenConfig.tokens.WETH, tokenConfig.tokens.IPAL, balancerV2VaultAddress, AssertToSelf, balancerV2WETHToIPALMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];
        var isFromETH = true;
        var isToETH = false;

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);

    } catch (error) {
        console.log(error)
    }
    //100 USDC -> ETH BalancerV2:100%
    try {
        console.log("\n===========(100 USDC -> ETH BalancerV2:100%)===========")
        var account = "0x19d675bbb76946785249a3ad8a805260e9420cb8"
        var blockNumber = 14665291
        var fromToken = tokenConfig.tokens.USDC
        var toToken = tokenConfig.tokens.WETH
        var amountIn = 100

        var balancerV2USDCToWETHMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "bytes32"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress,                                // to token address
                balancerV2WETHUSDCPoolId
            ]
        )

        var router1 = [
            ["balancerV2", 10000, tokenConfig.tokens.USDC, tokenConfig.tokens.WETH, balancerV2VaultAddress, AssertToSelf, balancerV2USDCToWETHMoreInfo],
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];
        var isFromETH = false;
        var isToETH = true;

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);

    } catch (error) {
        console.log(error)
    }
    //500 USDT -> WETH CurveV2:100%
    try {
        console.log("\n===========(500 USDT -> WETH CurveV2:100%)===========")
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
        
    } catch (error) {
        console.log(error)
    }

    // 500 USDT -> WETH Kyber:100%
    {
        console.log("\n===========(500 USDT -> WETH Kyber:100%)===========")
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
    //1 WETH -> USDT Kyber:50%
    //       -> USDT CurveV2:50%
    try {
        console.log("\n===========(1 WETH -> USDT Kyber:50%/CurveV2:50%)===========")
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
      
    } catch (error) {
        console.log(error)
    }
    //500 USDT -> USDC Kyber:50%
    //         -> USDC CurveV1:50%
    try {
        console.log("\n===========(500 USDT -> USDC Kyber:50%/CurveV1:50%)===========")
        var account = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.USDT
        var toToken = tokenConfig.tokens.USDC
        var amountIn = 5000

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
            ["kyber", 5000, tokenConfig.tokens.USDT, tokenConfig.tokens.USDC, kyberUSDCUSDTPoolAddress, kyberUSDCUSDTPoolAddress, kyberMoreInfo],
            ["curveV1", 5000, tokenConfig.tokens.USDT, tokenConfig.tokens.USDC, curveV1USDCUSDTPoolAddress, AssertToSelf, curveV1MoreInfo]
        ];

        var layer1 = [10000,[router1]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
    } catch (error) {
        console.log(error)
    }
    //  weth ->  usdc  (univ2)
    //       ->  usdc  (uniV3)
    //       ->  bnt  -> usdc (bancor)
    try {
        console.log("\n===========(WETH -> USDC uniV2:10%/uniV3:80%/bancor:10%(bnt->usdc))===========")
        var account = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
        var blockNumber = 14480567
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.USDC
        var amountIn = 0.06325

        var uniV2MoreInfo = "0x"
        var uniV3MoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                "1353119835187591902566005712305392",
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        tokenConfig.tokens.WETH.baseTokenAddress,
                        tokenConfig.tokens.USDC.baseTokenAddress,
                        3000
                    ]
                )
            ]
        )

        var bancorETHToBNTMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                tokenConfig.tokens.ETH.baseTokenAddress,                               // from token address
                tokenConfig.tokens.BNT.baseTokenAddress                                // to token address
            ]
        )
        var bancorBNTToUSDCMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                tokenConfig.tokens.BNT.baseTokenAddress,                               // from token address
                tokenConfig.tokens.USDC.baseTokenAddress                                // to token address
            ]
        )

        var router1 = [
            ["uniV2", 1000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDC, uniV2USDCWETHPoolAddr, uniV2USDCWETHPoolAddr, uniV2MoreInfo],
            ["uniV3", 8000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDC, uniV3USDCWETHPoolAddr, AssertToSelf, uniV3MoreInfo],
            ["bancor", 1000, tokenConfig.tokens.WETH, tokenConfig.tokens.BNT, bancorETHBNTPoolAddr, AssertToSelf, bancorETHToBNTMoreInfo],
        ];

        var router2 = [
            ["bancor", 10000, tokenConfig.tokens.BNT, tokenConfig.tokens.USDC, bancorBNTUSDCPoolAddr, AssertToSelf, bancorBNTToUSDCMoreInfo],
        ];


        var layer1 = [10000,[router1, router2]];
        var layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
        
    } catch (error) {
        console.log(error)
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

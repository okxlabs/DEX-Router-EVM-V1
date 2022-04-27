const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, packRawData, FOREVER } = require("./utils")
require("./utils/test_multi_x_factory");

async function main() {

    //1 ETH  -> USDT Kyber:50%
    //       -> USDT CurveV2:50%
    try {
        console.log("\n===========(1 ETH -> USDT Kyber:50%/CurveV2:50%)===========")
        var account = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
        var blockNumber = 14436483
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.USDT
        var amountIn = 1
        var isFromETH = true;
        var isToETH = false;

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
    // 0.06325 ETH  ->  usdc  (univ2)
    //              ->  usdc  (uniV3)
    //              ->  bnt  -> usdc (bancor)
    try {
        console.log("\n===========(0.06325 ETH -> USDC uniV2:10%/uniV3:80%/bancor:10%(bnt->usdc))===========")
        var account = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
        var blockNumber = 14480567
        var fromToken = tokenConfig.tokens.WETH
        var toToken = tokenConfig.tokens.USDC
        var amountIn = 0.06325
        var isFromETH = true;
        var isToETH = false;

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

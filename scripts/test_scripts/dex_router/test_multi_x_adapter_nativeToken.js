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
        let account = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
        let blockNumber = 14436483
        let fromToken = tokenConfig.tokens.WETH
        let toToken = tokenConfig.tokens.USDT
        let amountIn = 1
        let isFromETH = true;
        let isToETH = false;

        let kyberMoreInfo = "0x";

        let curveV2MoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128"],
            [
                fromToken.baseTokenAddress,
                toToken.baseTokenAddress,
                2,
                0
            ]
        )

        let router1 = [
            ["kyber", 5000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDT, kyberUSDTWETHPoolAddress, kyberUSDTWETHPoolAddress, kyberMoreInfo],
            ["curveV2", 5000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDT, curveV2USDTWETHPoolAddress, AssertToSelf, curveV2MoreInfo]
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];


        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);
      
    } catch (error) {
        console.log(error)
    }
    //1000 USDT -> ETH Kyber:50%
    //          -> ETH CurveV2:50%
    try {
        console.log("\n===========(1000 USDT -> ETH Kyber:50%/CurveV2:50%)===========")
        let account = "0x4bfa9e1c47087b0c78783adda7a18ff6461c97b1"
        let blockNumber = 14660040
        let fromToken = tokenConfig.tokens.USDT
        let toToken = tokenConfig.tokens.WETH
        let amountIn = 1
        let isFromETH = false;
        let isToETH = true;

        let kyberMoreInfo = "0x";

        let curveV2MoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128"],
            [
                fromToken.baseTokenAddress,
                toToken.baseTokenAddress,
                0,
                2
            ]
        )

        let router1 = [
            ["kyber", 5000, tokenConfig.tokens.USDT, tokenConfig.tokens.WETH, kyberUSDTWETHPoolAddress, kyberUSDTWETHPoolAddress, kyberMoreInfo],
            ["curveV2", 5000, tokenConfig.tokens.USDT, tokenConfig.tokens.WETH, curveV2USDTWETHPoolAddress, AssertToSelf, curveV2MoreInfo]
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];


        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);
      
    } catch (error) {
        console.log(error)
    }
    // 0.06325 ETH  ->  usdc  (univ2)
    //              ->  usdc  (uniV3)
    //              ->  bnt  -> usdc (bancor)
    try {
        console.log("\n===========(0.06325 ETH -> USDC uniV2:10%/uniV3:80%/bancor:10%(bnt->usdc))===========")
        let account = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
        let blockNumber = 14480567
        let fromToken = tokenConfig.tokens.WETH
        let toToken = tokenConfig.tokens.USDC
        let amountIn = 0.06325
        let isFromETH = true;
        let isToETH = false;

        let uniV2MoreInfo = "0x"
        let uniV3MoreInfo = ethers.utils.defaultAbiCoder.encode(
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

        let bancorETHToBNTMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                tokenConfig.tokens.ETH.baseTokenAddress,                               // from token address
                tokenConfig.tokens.BNT.baseTokenAddress                                // to token address
            ]
        )
        let bancorBNTToUSDCMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                tokenConfig.tokens.BNT.baseTokenAddress,                                // from token address
                tokenConfig.tokens.USDC.baseTokenAddress                                // to token address
            ]
        )

        let router1 = [
            ["uniV2", 1000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDC, uniV2USDCWETHPoolAddr, uniV2USDCWETHPoolAddr, uniV2MoreInfo],
            ["uniV3", 8000, tokenConfig.tokens.WETH, tokenConfig.tokens.USDC, uniV3USDCWETHPoolAddr, AssertToSelf, uniV3MoreInfo],
            ["bancor", 1000, tokenConfig.tokens.WETH, tokenConfig.tokens.BNT, bancorETHBNTPoolAddr, AssertToSelf, bancorETHToBNTMoreInfo],
        ];

        let router2 = [
            ["bancor", 10000, tokenConfig.tokens.BNT, tokenConfig.tokens.USDC, bancorBNTUSDCPoolAddr, AssertToSelf, bancorBNTToUSDCMoreInfo],
        ];


        let layer1 = [10000,[router1, router2]];
        let layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);
        
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

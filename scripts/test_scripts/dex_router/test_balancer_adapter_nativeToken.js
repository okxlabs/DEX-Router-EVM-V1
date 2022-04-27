const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, packRawData, FOREVER } = require("./utils")
require("./utils/test_multi_x_factory");

async function main() {

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
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

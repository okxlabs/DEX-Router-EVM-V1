const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, packRawData, FOREVER } = require("./utils")
require("./utils/test_multi_x_factory");

async function main() {

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
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

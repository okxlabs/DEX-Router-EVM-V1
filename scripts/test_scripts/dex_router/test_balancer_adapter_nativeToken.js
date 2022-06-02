const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
require("./utils/test_multi_x_factory");

async function main() {

    // 3.5 WETH -> AAVE BalancerV1:100%
    try {
        console.log("\n===========(3.5 WETH -> AAVE BalancerV1:100%)===========")
        let account = "0x260edfea92898a3c918a80212e937e6033f8489e"
        let blockNumber = 14436483
        let fromToken = tokenConfig.tokens.WETH
        let toToken = tokenConfig.tokens.AAVE
        let amountIn = 3.5

        let banlancerV1AAVEToWETHMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress                                // to token address
            ]
        )

        let router1 = [
            ["balancerV1", 10000, tokenConfig.tokens.WETH, tokenConfig.tokens.AAVE, banlancerV1AAVEWETHPoolAddress, AssertToSelf, banlancerV1AAVEToWETHMoreInfo],
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);
        
    } catch (error) {
        console.log(error)
    }
    //3.5 ETH -> AAVE BalancerV1:100%
    try {
        console.log("\n===========(3.5 ETH -> AAVE BalancerV1:100%)===========")
        let account = "0x260edfea92898a3c918a80212e937e6033f8489e"
        let blockNumber = 14436483
        let fromToken = tokenConfig.tokens.WETH
        let toToken = tokenConfig.tokens.AAVE
        let amountIn = 3.5

        let banlancerV1WETHToAAVEMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress                                // to token address
            ]
        )

        let router1 = [
            ["balancerV1", 10000, tokenConfig.tokens.WETH, tokenConfig.tokens.AAVE, banlancerV1AAVEWETHPoolAddress, AssertToSelf, banlancerV1WETHToAAVEMoreInfo],
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];
        let isFromETH = true;
        let isToETH = false;

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);
        
    } catch (error) {
        console.log(error)
    }
    // 3.5 AAVE -> ETH BalancerV1:100%
    try {
        console.log("\n===========(3.5 AAVE -> ETH BalancerV1:100%)===========")
        let account = "0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9"
        let blockNumber = 14659813
        let fromToken = tokenConfig.tokens.AAVE
        let toToken = tokenConfig.tokens.WETH
        let amountIn = 3.5

        let banlancerV1WETHToAAVEMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress                                // to token address
            ]
        )

        let router1 = [
            ["balancerV1", 10000, tokenConfig.tokens.AAVE, tokenConfig.tokens.WETH, banlancerV1AAVEWETHPoolAddress, AssertToSelf, banlancerV1WETHToAAVEMoreInfo],
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];
        let isFromETH = false;
        let isToETH = true;

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

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
require("./utils/test_multi_x_factory");

async function main() {

    //260 USDC -> BREED BalancerV2:100%
    try {
        console.log("\n===========(260 USDC -> BREED BalancerV2:100%)===========")
        let account = "0xd6745ac84d8d583c82afb267a52baeacbbf0a3e2"
        let blockNumber = 14665472 
        let fromToken = tokenConfig.tokens.USDC
        let toToken = tokenConfig.tokens.BREED
        let amountIn = 260

        let balancerV2USDCToBREEDMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "bytes32"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress,                                // to token address
                balancerV2USDCBREEDpoolId
            ]
        )

        let router1 = [
            ["balancerV2", 10000, tokenConfig.tokens.USDC, tokenConfig.tokens.BREED, balancerV2VaultAddress, AssertToSelf, balancerV2USDCToBREEDMoreInfo],
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer);

    } catch (error) {
        console.log(error)
    }
    //3.5 ETH -> IPAL BalancerV2:100%
    try {
        console.log("\n===========(3.5 ETH -> IPAL BalancerV2:100%)===========")
        let account = "0x260edfea92898a3c918a80212e937e6033f8489e"
        let blockNumber = 14436483
        let fromToken = tokenConfig.tokens.WETH
        let toToken = tokenConfig.tokens.IPAL
        let amountIn = 3.5

        let balancerV2WETHToIPALMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "bytes32"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress,                                // to token address
                balancerV2WETHIPALPoolId
            ]
        )

        let router1 = [
            ["balancerV2", 10000, tokenConfig.tokens.WETH, tokenConfig.tokens.IPAL, balancerV2VaultAddress, AssertToSelf, balancerV2WETHToIPALMoreInfo],
        ];

        let layer1 = [10000,[router1]];
        let layer = [layer1];
        let isFromETH = true;
        let isToETH = false;

        await executeMutilXAdapter(account, blockNumber, fromToken, toToken, amountIn, layer, isFromETH, isToETH);

    } catch (error) {
        console.log(error)
    }
    //100 USDC -> ETH BalancerV2:100%
    try {
        console.log("\n===========(100 USDC -> ETH BalancerV2:100%)===========")
        let account = "0x19d675bbb76946785249a3ad8a805260e9420cb8"
        let blockNumber = 14665291
        let fromToken = tokenConfig.tokens.USDC
        let toToken = tokenConfig.tokens.WETH
        let amountIn = 100

        let balancerV2USDCToWETHMoreInfo = ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "bytes32"],
            [
                fromToken.baseTokenAddress,                               // from token address 
                toToken.baseTokenAddress,                                // to token address
                balancerV2WETHUSDCPoolId
            ]
        )

        let router1 = [
            ["balancerV2", 10000, tokenConfig.tokens.USDC, tokenConfig.tokens.WETH, balancerV2VaultAddress, AssertToSelf, balancerV2USDCToWETHMoreInfo],
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

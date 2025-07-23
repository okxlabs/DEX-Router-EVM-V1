// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {AllBridgeAdapter} from "@okxlabs/adapter/AllBridgeAdapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/**
 * @title AllBridgeAdapterTest
 * @dev Test for AllBridge adapter (USDC/USDT stablecoin bridge)
 * @dev Tests token swaps between USDC and USDT on Ethereum
 * @dev Uses "eth" network identifier from foundry.toml
 */
contract AllBridgeAdapterTest is AbstractAdapterTest {
    
    // Token addresses on Ethereum mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    // AllBridge router and pool
    address constant ALLBRIDGE_ROUTER = 0x609c690e8F7D68a59885c9132e812eEbDaAf0c9e;
    address constant USDT_LP = 0x7DBF07Ad92Ed4e26D5511b4F285508eBF174135D; // Pool address
    
    /**
     * @dev Create AllBridge adapter
     */
    function createCustomAdapter() internal override returns (address) {
        return address(new AllBridgeAdapter(ALLBRIDGE_ROUTER));
    }
    
    /**
     * @dev Define test cases for AllBridge swaps
     */
    function getSwapTestCases() internal pure override returns (SwapTestCase[] memory) {
        SwapTestCase[] memory cases = new SwapTestCase[](2);
        
        // Test 1: USDC to USDT
        cases[0] = SwapTestCase({
            networkId: "eth", // Uses ETH network from foundry.toml
            forkBlock: 0, // Use latest block
            fromToken: USDC,
            toToken: USDT,
            pool: USDT_LP,
            amount: 1 * 10**6, // 1 USDC (6 decimals)
            expectedOutput: 0, // Dynamic
            sellBase: true, // USDC as base
            description: "USDC to USDT via AllBridge on ETH",
            moreInfo: abi.encode(bytes32(uint256(uint160(USDC))), bytes32(uint256(uint160(USDT))))
        });
        
        // Test 2: USDT to USDC  
        cases[1] = SwapTestCase({
            networkId: "eth",
            forkBlock: 0,
            fromToken: USDT,
            toToken: USDC,
            pool: USDT_LP,
            amount: 1 * 10**6, // 1 USDT (6 decimals)
            expectedOutput: 0,
            sellBase: false, // USDT as quote
            description: "USDT to USDC via AllBridge on ETH",
            moreInfo: abi.encode(bytes32(uint256(uint160(USDT))), bytes32(uint256(uint160(USDC))))
        });
        
        return cases;
    }
} 
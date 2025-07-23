// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {AaveV3StaticATokenAdapter} from "@okxlabs/adapter/AaveV3StaticATokenAdapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/**
 * @title AaveV3StaticATokenAdapterTest
 * @dev Test for Aave V3 Static aToken adapter
 * @dev Tests conversions between Static aTokens, aTokens, and underlying tokens
 * @dev Uses "eth" network identifier from foundry.toml
 */
contract AaveV3StaticATokenAdapterTest is AbstractAdapterTest {
    
    // Token addresses on Ethereum mainnet
    address constant STATA_ETH_USDT = 0x862c57d48becB45583AEbA3f489696D22466Ca1b; // Static aToken (pool)
    address constant AETH_USDT = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a; // aToken
    address constant ETH_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // Underlying USDT
    
    /**
     * @dev Create AaveV3StaticAToken adapter
     */
    function createCustomAdapter() internal override returns (address) {
        return address(new AaveV3StaticATokenAdapter());
    }
    
    /**
     * @dev Define test cases for Aave V3 Static aToken conversions
     */
    function getSwapTestCases() internal pure override returns (SwapTestCase[] memory) {
        SwapTestCase[] memory cases = new SwapTestCase[](4);
        
        // Test 1: Static aToken to underlying token (stataETHUSDT → USDT)
        cases[0] = SwapTestCase({
            networkId: "eth", // Uses ETH network from foundry.toml
            forkBlock: 20775914, // Latest block
            fromToken: STATA_ETH_USDT,
            toToken: ETH_USDT,
            pool: STATA_ETH_USDT,
            amount: 1000000, // 1 USDT (6 decimals)
            expectedOutput: 0, // Dynamic
            sellBase: true,
            description: "stataETHUSDT to USDT on ETH",
            moreInfo: abi.encode(STATA_ETH_USDT, ETH_USDT)
        });
        
        // Test 2: Static aToken to aToken (stataETHUSDT → aETHUSDT)
        cases[1] = SwapTestCase({
            networkId: "eth",
            forkBlock: 20775914,
            fromToken: STATA_ETH_USDT,
            toToken: AETH_USDT,
            pool: STATA_ETH_USDT,
            amount: 1000000,
            expectedOutput: 0,
            sellBase: true,
            description: "stataETHUSDT to aETHUSDT on ETH",
            moreInfo: abi.encode(STATA_ETH_USDT, AETH_USDT)
        });
        
        // Test 3: Underlying token to Static aToken (USDT → stataETHUSDT)
        cases[2] = SwapTestCase({
            networkId: "eth",
            forkBlock: 20775914,
            fromToken: ETH_USDT,
            toToken: STATA_ETH_USDT,
            pool: STATA_ETH_USDT,
            amount: 1000000,
            expectedOutput: 0,
            sellBase: false, // Use sellQuote for variety
            description: "USDT to stataETHUSDT on ETH",
            moreInfo: abi.encode(ETH_USDT, STATA_ETH_USDT)
        });
        
        // Test 4: aToken to Static aToken (aETHUSDT → stataETHUSDT)
        cases[3] = SwapTestCase({
            networkId: "eth",
            forkBlock: 20775914,
            fromToken: AETH_USDT,
            toToken: STATA_ETH_USDT,
            pool: STATA_ETH_USDT,
            amount: 1000000,
            expectedOutput: 0,
            sellBase: false,
            description: "aETHUSDT to stataETHUSDT on ETH",
            moreInfo: abi.encode(AETH_USDT, STATA_ETH_USDT)
        });
        
        return cases;
    }
} 
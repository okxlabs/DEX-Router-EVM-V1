// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {UniV4AdapterV2} from "@dex/adapter/UniV4AdapterV2.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";
import {Currency} from "@dex/types/Currency.sol";

/// @title UniV4AdapterV2Test
/// @notice Adapter tests for UniV4AdapterV2
/// @dev Uses the new AbstractAdapterTest harness to minimise boilerplate.
contract UniV4AdapterV2Test is AbstractAdapterTest {
    struct PathKey {
        Currency inputCurrency; //from token
        Currency intermediateCurrency; //intermediate token
        uint24 fee;
        int24 tickSpacing;
    }

    // Mapping of network IDs to their pool managers and wrapped tokens
    mapping(string => address) internal poolManagers;
    mapping(string => address) internal wrappedTokens;
    
    /**
     * @dev Create UniV4AdapterV2 adapter for the specified network
     * @param networkId The network identifier (e.g. "eth", "bsc")
     */
    function createCustomAdapter(string memory networkId) internal override returns (address) {
        // Pool manager addresses per network
        poolManagers["eth"] = 0x000000000004444c5dc75cB358380D2e3dE08A90;
        poolManagers["bsc"] = 0x000000000004444c5dc75cB358380D2e3dE08A90;
        
        // Wrapped token addresses per network
        wrappedTokens["eth"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        wrappedTokens["bsc"] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB

        address poolManager = poolManagers[networkId];
        address wrappedToken = wrappedTokens[networkId];
        require(poolManager != address(0), "Unsupported network");
        require(wrappedToken != address(0), "Unsupported network");
        
        return address(
            new UniV4AdapterV2(
                poolManager,
                wrappedToken
            )
        );
    }

    /**
     * @dev Define test cases for UniV4 multihop swaps
     */
    function getSwapTestCases()
        internal
        pure
        override
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](1);
        cases[0] = getEthMainnetTestCases();

        return cases;
    }

    function getEthMainnetTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses on Ethereum mainnet
        address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address USDe = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;

        // Pool manager address
        address POOL_MANAGER = 0x000000000004444c5dc75cB358380D2e3dE08A90;

        SwapTestCase[] memory cases = new SwapTestCase[](5);

        // Test 1: ETH to USDT (single hop)
        PathKey[] memory pathKeys1 = new PathKey[](1);
        pathKeys1[0] = PathKey({
            inputCurrency: Currency.wrap(address(0)),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10
        });

        cases[0] = SwapTestCase({
            networkId: "eth",
            forkBlock: 21799331,
            fromToken: WETH,
            toToken: USDT,
            pool: POOL_MANAGER,
            amount: 30000000000000000, // 0.03 ETH
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "WETH to USDT on UniV4",
            moreInfo: abi.encode(pathKeys1),
            fromTokenPreTo: address(0)
        });

        // Test 2: USDT to USDe (single hop)
        PathKey[] memory pathKeys2 = new PathKey[](1);
        pathKeys2[0] = PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(USDe),
            fee: 100,
            tickSpacing: 1
        });

        cases[1] = SwapTestCase({
            networkId: "eth",
            forkBlock: 21799331,
            fromToken: USDT,
            toToken: USDe,
            pool: POOL_MANAGER,
            amount: 1 * 10 ** 6, // 1 USDT
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "USDT to USDe on UniV4",
            moreInfo: abi.encode(pathKeys2),
            fromTokenPreTo: address(0)
        });

        // Test 3: ETH to USDT to USDe (multihop)
        PathKey[] memory pathKeys3 = new PathKey[](2);
        pathKeys3[0] = PathKey({
            inputCurrency: Currency.wrap(address(0)),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10
        });
        pathKeys3[1] = PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(USDe),
            fee: 100,
            tickSpacing: 1
        });

        cases[2] = SwapTestCase({
            networkId: "eth",
            forkBlock: 21799331,
            fromToken: WETH,
            toToken: USDe,
            pool: POOL_MANAGER,
            amount: 0.03 ether, // 0.03 ETH
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "WETH to USDT to USDe on UniV4 (multihop)",
            moreInfo: abi.encode(pathKeys3),
            fromTokenPreTo: address(0)
        });

        // Test 4: USDe to USDT (single hop)
        PathKey[] memory pathKeys4 = new PathKey[](1);
        pathKeys4[0] = PathKey({
            inputCurrency: Currency.wrap(USDe),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 100,
            tickSpacing: 1
        });

        cases[3] = SwapTestCase({
            networkId: "eth",
            forkBlock: 21799331,
            fromToken: USDe,
            toToken: USDT,
            pool: POOL_MANAGER,
            amount: 1 ether, // 1 USDe
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "USDe to USDT on UniV4",
            moreInfo: abi.encode(pathKeys4),
            fromTokenPreTo: address(0)
        });

        // Test 5: USDT to ETH (single hop)
        PathKey[] memory pathKeys5 = new PathKey[](1);
        pathKeys5[0] = PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(address(0)),
            fee: 500,
            tickSpacing: 10
        });

        cases[4] = SwapTestCase({
            networkId: "eth",
            forkBlock: 21799331,
            fromToken: USDT,
            toToken: WETH,
            pool: POOL_MANAGER,
            amount: 5 * 10 ** 6, // 5 USDT
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "USDT to WETH on UniV4",
            moreInfo: abi.encode(pathKeys5),
            fromTokenPreTo: address(0)
        });

        return cases;
    }
} 
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {UniV4HookAdapter} from "@dex/adapter/UniV4HookAdapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";
import {Currency} from "@dex/types/Currency.sol";
/// @title UniV4AdapterV2Test
/// @notice Adapter tests for UniV4AdapterV2
/// @dev Uses the new AbstractAdapterTest harness to minimise boilerplate.
contract UniV4HookAdapterTest is AbstractAdapterTest {

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
        poolManagers["base"] = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
        
        // Wrapped token addresses per network
        wrappedTokens["eth"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        wrappedTokens["bsc"] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
        wrappedTokens["base"] = 0x4200000000000000000000000000000000000006; // WETH

        address poolManager = poolManagers[networkId];
        address wrappedToken = wrappedTokens[networkId];
        require(poolManager != address(0), "Unsupported network");
        require(wrappedToken != address(0), "Unsupported network");
        
        return address(
            new UniV4HookAdapter(
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
        SwapTestCase[][] memory cases = new SwapTestCase[][](3);
        cases[0] = getUniV4TestCases();
        cases[1] = getClankerTestCases();
        cases[2] = getZoraTestCases();

        return cases;
    }

    function getUniV4TestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses on Ethereum mainnet
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address USDe = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;

        // Pool manager address
        address POOL_MANAGER = 0x000000000004444c5dc75cB358380D2e3dE08A90;

        SwapTestCase[] memory cases = new SwapTestCase[](5);

        // Test 1: ETH to USDT (single hop)
        UniV4HookAdapter.PathKey[] memory pathKeys1 = new UniV4HookAdapter.PathKey[](1);
        pathKeys1[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(address(0)),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hook: address(0),
            hookData: ""
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
        UniV4HookAdapter.PathKey[] memory pathKeys2 = new UniV4HookAdapter.PathKey[](1);
        pathKeys2[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(USDe),
            fee: 100,
            tickSpacing: 1,
            hook: address(0),
            hookData: ""
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
        UniV4HookAdapter.PathKey[] memory pathKeys3 = new UniV4HookAdapter.PathKey[](2);
        pathKeys3[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(address(0)),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hook: address(0),
            hookData: ""
        });
        pathKeys3[1] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(USDe),
            fee: 100,
            tickSpacing: 1,
            hook: address(0),
            hookData: ""
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
        UniV4HookAdapter.PathKey[] memory pathKeys4 = new UniV4HookAdapter.PathKey[](1);
        pathKeys4[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(USDe),
            intermediateCurrency: Currency.wrap(USDT),
            fee: 100,
            tickSpacing: 1,
            hook: address(0),
            hookData: ""
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
        UniV4HookAdapter.PathKey[] memory pathKeys5 = new UniV4HookAdapter.PathKey[](1);
        pathKeys5[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(USDT),
            intermediateCurrency: Currency.wrap(address(0)),
            fee: 500,
            tickSpacing: 10,
            hook: address(0),
            hookData: ""
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

    function getClankerTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        address weth = 0x4200000000000000000000000000000000000006;
        address digits = 0x9b1b877442f34Bf7Fb7bdbEdC0Ef84e279deFB07;

        address clankerStaticHook = 0xDd5EeaFf7BD481AD55Db083062b13a3cdf0A68CC;

        SwapTestCase[] memory cases = new SwapTestCase[](1);
        // Test 1: WETH to DIGITS
        // input/output amount should match exactly with this txn:
        // https://basescan.org/tx/0x5cb73831010deab51e3ed429dd0f51edea7c5ac25e27b0f6c2d6f363204cc109
        UniV4HookAdapter.PathKey[] memory pathKeys = new UniV4HookAdapter.PathKey[](1);
        pathKeys[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(weth),
            intermediateCurrency: Currency.wrap(digits),        
            fee: 8388608,
            tickSpacing: 200,
            hook: clankerStaticHook,
            hookData: ""
        });
        cases[0] = SwapTestCase({
            networkId: "base", // Uses Base network from foundry.toml
            forkBlock: 33487138, // Block from the actual transaction
            fromToken: weth,
            toToken: digits,
            pool: clankerStaticHook, // actually hook address
            amount: 0.0009985 * 10 ** 18, // 0.0009985 WETH
            expectedOutput: 1629695008313360358895439,
            sellBase: true,
            expectRevert: false,
            description: "WETH to DIGITS on Base via ClankerV4 (actual txn)",
            moreInfo: abi.encode(pathKeys),
            fromTokenPreTo: address(0)
        });

        return cases;
    }

    function getZoraTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        address zora = 0x1111111111166b7FE7bd91427724B487980aFc69;
        address creatorCoin = 0x3D73a27fB609a7c6f83ACEB3a59304229BFAf1f2;
        address contentCoin = 0x46affC83DAa0A4E20C832B956C1B1cDc86D4f905;

        address creatorHook = 0x5e5D19d22c85A4aef7C1FdF25fB22A5a38f71040;
        address contentHook = 0x9ea932730A7787000042e34390B8E435dD839040;

        SwapTestCase[] memory cases = new SwapTestCase[](2);
        // Test 1: ZORA to CREATOR-COIN
        UniV4HookAdapter.PathKey[] memory pathKeys = new UniV4HookAdapter.PathKey[](1);
        pathKeys[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(zora),
            intermediateCurrency: Currency.wrap(creatorCoin),        
            fee: 30000,
            tickSpacing: 200,
            hook: creatorHook,
            hookData: ""
        });
        cases[0] = SwapTestCase({
            networkId: "base", // Uses Base network from foundry.toml
            forkBlock: 33536464, // Block from the actual transaction
            fromToken: zora,
            toToken: creatorCoin,
            pool: creatorHook, // actually hook address
            amount: 10 * 10 ** 18,
            expectedOutput: 0,
            sellBase: true,
            expectRevert: false,
            description: "ZORA to CREATOR COIN",
            moreInfo: abi.encode(pathKeys),
            fromTokenPreTo: address(0)
        });

        
        // Test 2: CREATOR-COIN to CONTENT-COIN
        UniV4HookAdapter.PathKey[] memory pathKeys2 = new UniV4HookAdapter.PathKey[](2);
        pathKeys2[0] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(zora),
            intermediateCurrency: Currency.wrap(creatorCoin),        
            fee: 30000,
            tickSpacing: 200,
            hook: creatorHook,
            hookData: ""
        });
        pathKeys2[1] = UniV4HookAdapter.PathKey({
            inputCurrency: Currency.wrap(creatorCoin),
            intermediateCurrency: Currency.wrap(contentCoin),        
            fee: 30000,
            tickSpacing: 200,
            hook: contentHook,
            hookData: ""
        });
        cases[1] = SwapTestCase({
            networkId: "base", // Uses Base network from foundry.toml
            forkBlock: 33536464, // Block from the actual transaction
            fromToken: zora,
            toToken: contentCoin,
            pool: contentHook, // actually hook address
            amount: 10000 * 10 ** 18,
            expectedOutput: 83825140651864056431958546,
            sellBase: true,
            expectRevert: false,
            description: "ZORA to CREATOR COIN to CONTENT COIN",
            moreInfo: abi.encode(pathKeys2),
            fromTokenPreTo: address(0)
        });

        return cases;
    }
} 
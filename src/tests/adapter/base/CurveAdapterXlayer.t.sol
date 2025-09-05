// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {CurveAdapter} from "@dex/adapter/CurveAdapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/// @title CurveAdapter Xlayer Test
/// @notice Adapter tests for CurveAdapter on Xlayer
/// @dev Uses the new AbstractAdapterTest harness to minimise boilerplate.
contract CurveAdapterXlayerTest is AbstractAdapterTest {
    address public immutable WETH_ADDRESS = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
    /**
     * @dev Create CurveAdapter
     */
    function createCustomAdapter(
        string memory /* networkId */
    ) internal override returns (address) {
        return address(new CurveAdapter(WETH_ADDRESS));
    }

    /**
     * @dev Define test cases for CurveAdapter swaps
     */
    function getSwapTestCases()
        internal
        override
        pure
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](1);
        cases[0] = getCurveAdapterTestCases();

        return cases;
    }

    function getCurveAdapterTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses on Xlayer network
        address USDC = 0x74b7F16337b8972027F6196A17a631aC6dE26d22;
        address USDT = 0x1E4a5963aBFD975d8c9021ce480b42188849D41d;

        // Pool addresses
        address USDCUSDT_2pool = 0xD1b30BA128573fcd7D141C8A987961b40e047BB6;

        SwapTestCase[] memory cases = new SwapTestCase[](2);

        // Test 1: USDC to USDT
        // tx: https://www.oklink.com/zh-hans/x-layer/tx/0x855db68d7b37e9ec98054cae1939dbb762feddf7b22dd8abfff2404c0691ce40
        cases[0] = SwapTestCase({
            networkId: "xlayer",
            forkBlock: 30480017,
            fromToken: USDC,
            toToken: USDT,
            pool: USDCUSDT_2pool,
            amount: 34999800104,
            expectedOutput: 34991444965,
            sellBase: true,
            expectRevert: false,
            description: "USDC to USDT on Xlayer CurveAdapter",
            moreInfo: abi.encode(USDC, USDT, int128(0), int128(1), false),
            fromTokenPreTo: address(0) // no need to transfer tokens to pool first
        });

        // Test 2: USDT to USDC
        // tx: https://www.oklink.com/zh-hans/x-layer/tx/0x2e1de3f191e8c2b3328f86d1fdd03fb90d7e0c3a5d89bda1656abe31f17f0046
        cases[1] = SwapTestCase({
            networkId: "xlayer",
            forkBlock: 30356279,
            fromToken: USDT,
            toToken: USDC,
            pool: USDCUSDT_2pool,
            amount: 264711216,
            expectedOutput: 264711117,
            sellBase: true,
            expectRevert: false,
            description: "USDT to USDC on Xlayer CurveAdapter",
            moreInfo: abi.encode(USDT, USDC, int128(1), int128(0), false),
            fromTokenPreTo: address(0) // no need to transfer tokens to pool first
        });

        return cases;
    }
} 
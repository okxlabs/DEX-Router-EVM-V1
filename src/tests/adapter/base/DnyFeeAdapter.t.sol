// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {DnyFeeAdapter} from "@dex/adapter/DnyFeeAdapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/// @title DnyFeeAdapter
/// @notice Adapter tests for DnyFeeAdapter
/// @dev Uses the new AbstractAdapterTest harness to minimise boilerplate.
contract DnyFeeAdapterTest is AbstractAdapterTest {
    /**
     * @dev Create DnyFeeAdapter
     */
    function createCustomAdapter(
        string memory /* networkId */
    ) internal override returns (address) {
        return address(new DnyFeeAdapter());
    }

    /**
     * @dev Define test cases for DnyFeeAdapter swaps
     */
    function getSwapTestCases()
        internal
        override
        pure
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](1);
        cases[0] = getRocketForkUniV2TestCases();

        return cases;
    }

    function getRocketForkUniV2TestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses on Base network
        address WETH = 0x4200000000000000000000000000000000000006;
        address RCKT = 0x6653dD4B92a0e5Bf8ae570A98906d9D6fD2eEc09;
        address axlUSDC = 0xEB466342C4d449BC9f53A865D5Cb90586f405215;

        // Pool addresses
        address RCKTaxlUSDC = 0x1a7975836BD4f1a53e5251F41b6DA5FF5FD105f5;
        address axlUSDCWETH = 0x86cd8533b0166BDcF5d366A3Bb0c3465E56D3ad5;

        SwapTestCase[] memory cases = new SwapTestCase[](2);

        // Test 1: RCKT to axlUSDC
        // tx: https://basescan.org/tx/0x58d6b6e915bec61d737c3c4311cd4aedc9e5434f8e9804a0d1614b5314fef9c5
        // fee: 3/1000 (30)
        cases[0] = SwapTestCase({
            networkId: "base",
            forkBlock: 3781130,
            fromToken: RCKT,
            toToken: axlUSDC,
            pool: RCKTaxlUSDC,
            amount: 2 * 10 ** 18, // 2 RCKT
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "RCKT to axlUSDC on Base RocketForkUniV2",
            moreInfo: abi.encode(uint256(30)), // 3/1000 fee
            fromTokenPreTo: RCKTaxlUSDC // Transfer tokens to pool first
        });

        // Test 2: axlUSDC to WETH
        // tx: https://basescan.org/tx/0x5c9777c05d10055f8315944bae54f3ebf3733df315c4f74f7354182742acbc8d
        // fee: 3/1000 (30)
        cases[1] = SwapTestCase({
            networkId: "base",
            forkBlock: 3802311,
            fromToken: axlUSDC,
            toToken: WETH,
            pool: axlUSDCWETH,
            amount: 0.1 * 10 ** 6, // 0.1 axlUSDC
            expectedOutput: 0, // dynamic
            sellBase: false, // axlUSDC is quote token
            expectRevert: false,
            description: "axlUSDC to WETH on Base RocketForkUniV2",
            moreInfo: abi.encode(uint256(30)), // 3/1000 fee
            fromTokenPreTo: axlUSDCWETH // Transfer tokens to pool first
        });

        return cases;
    }
} 
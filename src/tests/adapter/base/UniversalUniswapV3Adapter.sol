// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {UniversalUniswapV3Adapter} from "@dex/adapter/TemplateAdapter/UniversalUniswapV3Adapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/// @title UniversalUniswapV3Adapter
/// @notice Adapter tests for UniversalUniswapV3Adapter
/// @dev Uses the new AbstractAdapterTest harness to minimise boilerplate.
contract UniversalUniswapV3AdapterTest is AbstractAdapterTest {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /**
     * @dev Create UniversalUniswapV3Adapter
     */
    function createCustomAdapter(
        string memory networkId
    ) internal override returns (address) {
        address nativeWrappedToken = _getNativeWrappedToken(networkId);
        return
            address(
                new UniversalUniswapV3Adapter(
                    payable(nativeWrappedToken),
                    MIN_SQRT_RATIO,
                    MAX_SQRT_RATIO
                )
            );
    }

    function _getNativeWrappedToken(
        string memory networkId
    ) internal pure returns (address) {
        bytes32 id = keccak256(bytes(networkId));
        if (id == keccak256("bsc")) {
            return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        } else if (id == keccak256("mantle")) {
            return 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
        } else {
            revert("Invalid network");
        }
    }

    /**
     * @dev Define test cases for UniversalUniswapV3Adapter swaps
     */
    function getSwapTestCases()
        internal
        pure
        override
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](2);
        cases[0] = getThenaV3TestCases();
        cases[1] = getAgniFinanceTestCases();

        return cases;
    }

    function getThenaV3TestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Wrapped BNB
        address ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; // Ethereum

        // Thena V3 (Algebra Integral) pool containing WBNB / ETH
        address WBNB_ETH_POOL = 0x58F04AAda1051885a3C4e296aaB0A454Ea1233A3;
        SwapTestCase[] memory cases = new SwapTestCase[](2);

        // Test 1: WBNB to ETH
        cases[0] = SwapTestCase({
            networkId: "bsc",
            forkBlock: 55363063, // latest head
            fromToken: WBNB,
            toToken: ETH,
            pool: WBNB_ETH_POOL,
            amount: 1 * 10 ** 18, // 1 WBNB (BSC WBNB has 18 decimals)
            expectedOutput: 207698750360467694, // dynamic
            sellBase: false,
            expectRevert: false,
            description: "WBNB to ETH on Thena V3",
            moreInfo: abi.encode(uint160(0), abi.encode(WBNB, ETH, uint24(0)))
        });

        // Test 2: ETH to WBNB
        cases[1] = SwapTestCase({
            networkId: "bsc",
            forkBlock: 0, // latest
            fromToken: ETH,
            toToken: WBNB,
            pool: WBNB_ETH_POOL,
            amount: 0.1 * 10 ** 18, // 0.1 ETH
            expectedOutput: 0, // dynamic
            sellBase: true,
            expectRevert: false,
            description: "ETH to WBNB on Thena V3",
            moreInfo: abi.encode(uint160(0), abi.encode(ETH, WBNB, uint24(0)))
        });

        return cases;
    }

    function getAgniFinanceTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses on Mantle network
        address WMNT = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
        address WETH = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;
        address USDT = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;

        // Pool addresses
        address WMNT_USDT = 0xD08C50F7E69e9aeb2867DefF4A8053d9A855e26A;
        address WETH_USDT = 0x628f7131CF43e88EBe3921Ae78C4bA0C31872bd4;

        SwapTestCase[] memory cases = new SwapTestCase[](4);

        // Test 1: WMNT to USDT
        // //https://explorer.mantle.xyz/tx/0x49e745b9582d202b744a140c3a7e6aa8cd4a2bb2a282609b413696ddd899eebe
        cases[0] = SwapTestCase({
            networkId: "mantle", // Uses Mantle network from foundry.toml
            forkBlock: 62825725, // Block before the transaction
            fromToken: WMNT,
            toToken: USDT,
            pool: WMNT_USDT,
            amount: 0.415 * 10 ** 18, // 0.415 WMNT
            expectedOutput: 0.504974 * 10 ** 6,
            sellBase: true,
            expectRevert: false,
            description: "WMNT to USDT on Mantle",
            moreInfo: abi.encode(uint160(0), abi.encode(WMNT, USDT))
        });

        // Test 2: USDT to WMNT
        cases[1] = SwapTestCase({
            networkId: "mantle",
            forkBlock: 62825725,
            fromToken: USDT,
            toToken: WMNT,
            pool: WMNT_USDT,
            amount: 1000000, // 1 USDT (6 decimals)
            expectedOutput: 0,
            sellBase: false, // USDT is quote token
            expectRevert: false,
            description: "USDT to WMNT on Mantle",
            moreInfo: abi.encode(uint160(0), abi.encode(USDT, WMNT))
        });

        // Test 3: WETH to USDT
        cases[2] = SwapTestCase({
            networkId: "mantle",
            forkBlock: 62825725,
            fromToken: WETH,
            toToken: USDT,
            pool: WETH_USDT,
            amount: 1 ether, // 1 WETH
            expectedOutput: 0,
            sellBase: true,
            expectRevert: false,
            description: "WETH to USDT on Mantle",
            moreInfo: abi.encode(uint160(0), abi.encode(WETH, USDT))
        });

        // Test 4: USDT to WETH
        cases[3] = SwapTestCase({
            networkId: "mantle",
            forkBlock: 62825725,
            fromToken: USDT,
            toToken: WETH,
            pool: WETH_USDT,
            amount: 3000 * 10 ** 6, // 3000 USDT
            expectedOutput: 0,
            sellBase: false,
            expectRevert: false,
            description: "USDT to WETH on Mantle",
            moreInfo: abi.encode(uint160(0), abi.encode(USDT, WETH))
        });

        return cases;
    }
}

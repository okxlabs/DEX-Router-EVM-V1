// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

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

    // Mapping of network IDs to their native wrapped tokens
    mapping(string => address) internal nativeWrappedTokens;
    
    /**
     * @dev Create UniversalUniswapV3 adapter for the specified network
     * @param networkId The network identifier (e.g. "bsc", "mantle")
     */
    function createCustomAdapter(string memory networkId) internal override returns (address) {
        // Native wrapped token addresses per network
        nativeWrappedTokens["bsc"] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // BSC_WBNB
        nativeWrappedTokens["mantle"] = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; // MANTLE_WMNT
        nativeWrappedTokens["xlayer"] = 0xe538905cf8410324e03A5A23C1c177a474D59b2b; // XLAYER_WOKB
        nativeWrappedTokens["linea"] = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f; // LINEA_WETH

        address nativeWrappedToken = nativeWrappedTokens[networkId];
        require(nativeWrappedToken != address(0), "Unsupported network");
        
        return address(
            new UniversalUniswapV3Adapter(
                payable(nativeWrappedToken),
                MIN_SQRT_RATIO,
                MAX_SQRT_RATIO
            )
        );
    }

    /**
     * @dev Define test cases for Thena V3 swaps
     */
    function getSwapTestCases()
        internal
        pure
        override
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](4);
        cases[0] = getThenaV3TestCases();
        cases[1] = getAgniFinanceTestCases();
        cases[2] = getOkieV3XlayerTestCases();
        cases[3] = getEtherexFinanceTestCases();

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
            expectedOutput: 207698750360467694, 
            sellBase: false,
            expectRevert: false,
            description: "WBNB to ETH on Thena V3",
            moreInfo: abi.encode(uint160(0), abi.encode(WBNB, ETH, uint24(0))),
            fromTokenPreTo: address(0)
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
            moreInfo: abi.encode(uint160(0), abi.encode(ETH, WBNB, uint24(0))),
            fromTokenPreTo: address(0)
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
            moreInfo: abi.encode(uint160(0), abi.encode(WMNT, USDT)),
            fromTokenPreTo: address(0)
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
            moreInfo: abi.encode(uint160(0), abi.encode(USDT, WMNT)),
            fromTokenPreTo: address(0)
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
            moreInfo: abi.encode(uint160(0), abi.encode(WETH, USDT)),
            fromTokenPreTo: address(0)
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
            moreInfo: abi.encode(uint160(0), abi.encode(USDT, WETH)),
            fromTokenPreTo: address(0)
        });

        return cases;
    }

    function getOkieV3XlayerTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {

        address WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b; // WOKB
        address USDC = 0x74b7F16337b8972027F6196A17a631aC6dE26d22; // USDC
        address USDT = 0x1E4a5963aBFD975d8c9021ce480b42188849D41d; // USDT
        address USDC_WOKB = 0x01cA49E4a864C49FeDd08B464c042d02598C3538; // USDC_WOKB
        address USDT_USDC = 0x2b0Fea5Cbe72dcd362fbcA452FEdD57F55747ae3;

        SwapTestCase[] memory cases = new SwapTestCase[](2);


        // Test 1: WOKB to USDC
        // https://www.oklink.com/x-layer/tx/0x6410c2b72c26cab1a678c974bf08a45983e120743e1f27449b2fa76528e3258b
        cases[0] = SwapTestCase({
            networkId: "xlayer",
            forkBlock: 31552191 - 1,
            fromToken: WOKB,
            toToken: USDC,
            pool: USDC_WOKB,
            amount: 59248269621225,
            expectedOutput: 27394,
            sellBase: false,
            expectRevert: false,
            description: "EQUA to WOKB on USDC",
            moreInfo: abi.encode(uint160(0), abi.encode(WOKB, USDC)),
            fromTokenPreTo: address(0)
        });

        // Test 2: USDC to USDT
        // https://www.oklink.com/x-layer/tx/0x7488890d8df542199ee23acdb9ce473806d23573eb2bb0a5e806abc83b98c2fa/log
        cases[1] = SwapTestCase({
            networkId: "xlayer",
            forkBlock: 31793708 -1,
            fromToken: USDC,
            toToken: USDT,
            pool: USDT_USDC,
            amount: 4172816,
            expectedOutput: 4167156,
            sellBase: false,
            expectRevert: false,
            description: "USDT to USDC on OKIE",
            moreInfo: abi.encode(uint160(0), abi.encode(USDC, USDT)),
            fromTokenPreTo: address(0)
        });

        return cases;
    }

    function getEtherexFinanceTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        // Token addresses on linea
        address WETH = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
        address USDT = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;

        // Pool addresses
        address WETH_USDT = 0xd5E04ba35908D7bF5BD2eAd7e3e14d21df07DC01;

        SwapTestCase[] memory cases = new SwapTestCase[](1);

        // Test 1: WETH to USDT
        // https://lineascan.build/tx/0xac0add9f82fc5f131963c32667ee16b55cef76d35aacda86ad9a2aacbdca7408
        cases[0] = SwapTestCase({
            networkId: "linea",
            forkBlock: 21882671 - 1,
            fromToken: WETH,
            toToken: USDT,
            pool: WETH_USDT,
            amount: 1.5 * 10 ** 18, // 0.45 WETH
            expectedOutput: 6445.447958 * 10 ** 6,
            sellBase: false,
            expectRevert: false,
            description: "WETH to USDT in Etherex on Linea",
            moreInfo: abi.encode(uint160(0), abi.encode(WETH, USDT)),
            fromTokenPreTo: address(0)
        });

        return cases;
    }
}

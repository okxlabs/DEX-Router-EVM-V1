// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

/**
 * @title UniV3ExactOutExecutor Logic Tests
 * @notice Tests for the core logic and data structures used in UniV3ExactOutExecutor
 * @dev This test focuses on testing the encoding/decoding logic, constants, and helper functions
 *      without importing the actual contracts to avoid conflicts
 */
contract UniV3ExactOutExecutorLogicTest is Test {
    
    // Constants from UniV3ExactOutExecutor and CommonUtils
    uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _WETH_MASK = 1 << 254;
    uint256 private constant _WETH_UNWRAP_MASK = 1 << 253;
    
    // Uniswap V3 constants
    uint160 private constant _MIN_SQRT_RATIO = 4_295_128_739 + 1;
    uint160 private constant _MAX_SQRT_RATIO = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_342 - 1;
    
    // Test addresses (Ethereum mainnet)
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    // Uniswap V3 pool addresses
    address constant USDC_WETH_V3_POOL = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // 0.05% fee
    address constant DAI_WETH_V3_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;   // 0.3% fee
    address constant USDC_USDT_V3_POOL = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6;  // 0.01% fee
    
    address user = makeAddr("user");
    
    function setUp() public {
        // Fork Ethereum mainnet for realistic pool addresses
        vm.createSelectFork("eth", 18500000);
    }
    
    // ========== Pool Encoding Tests ==========
    
    function testPoolAddressEncoding() public {
        uint256 poolData = _buildV3Pool(USDC_WETH_V3_POOL, false, false);
        address extractedPool = address(uint160(poolData & _ADDRESS_MASK));
        
        assertEq(extractedPool, USDC_WETH_V3_POOL, "Pool address should be correctly encoded and extracted");
    }
    
    function testZeroForOneFlagEncoding() public {
        // Test zeroForOne = true
        uint256 poolDataTrue = _buildV3Pool(USDC_WETH_V3_POOL, true, false);
        bool zeroForOneTrue = (poolDataTrue & _ONE_FOR_ZERO_MASK) == 0;
        assertTrue(zeroForOneTrue, "zeroForOne=true should encode correctly");
        
        // Test zeroForOne = false
        uint256 poolDataFalse = _buildV3Pool(USDC_WETH_V3_POOL, false, false);
        bool zeroForOneFalse = (poolDataFalse & _ONE_FOR_ZERO_MASK) == 0;
        assertFalse(zeroForOneFalse, "zeroForOne=false should encode correctly");
    }
    
    function testWETHUnwrapFlagEncoding() public {
        // Test unwrap = true
        uint256 poolDataWithUnwrap = _buildV3Pool(USDC_WETH_V3_POOL, true, true);
        bool shouldUnwrap = (poolDataWithUnwrap & _WETH_UNWRAP_MASK) != 0;
        assertTrue(shouldUnwrap, "WETH unwrap flag should be set when unwrap=true");
        
        // Test unwrap = false
        uint256 poolDataWithoutUnwrap = _buildV3Pool(USDC_WETH_V3_POOL, true, false);
        bool shouldNotUnwrap = (poolDataWithoutUnwrap & _WETH_UNWRAP_MASK) != 0;
        assertFalse(shouldNotUnwrap, "WETH unwrap flag should not be set when unwrap=false");
    }
    
    function testWETHMaskEncoding() public {
        // Test WETH mask (used in execute function)
        uint256 poolDataWithWETHMask = uint256(uint160(USDC_WETH_V3_POOL)) | _WETH_MASK;
        bool hasWETHMask = (poolDataWithWETHMask & _WETH_MASK) != 0;
        assertTrue(hasWETHMask, "WETH mask should be detectable");
        
        uint256 poolDataWithoutWETHMask = uint256(uint160(USDC_WETH_V3_POOL));
        bool hasNoWETHMask = (poolDataWithoutWETHMask & _WETH_MASK) != 0;
        assertFalse(hasNoWETHMask, "WETH mask should not be present by default");
    }
    
    // ========== Multi-Pool Encoding Tests ==========
    
    function testSinglePoolEncoding() public {
        uint256[] memory pools = new uint256[](1);
        pools[0] = _buildV3Pool(USDC_WETH_V3_POOL, false, false); // WETH -> USDC
        
        bytes memory executorData = abi.encode(pools);
        (uint256[] memory decodedPools) = abi.decode(executorData, (uint256[]));
        
        assertEq(decodedPools.length, 1, "Should decode single pool correctly");
        assertEq(decodedPools[0], pools[0], "Pool data should match");
    }
    
    function testTwoPoolEncoding() public {
        uint256[] memory pools = new uint256[](2);
        pools[0] = _buildV3Pool(USDC_WETH_V3_POOL, true, false);  // USDC -> WETH
        pools[1] = _buildV3Pool(DAI_WETH_V3_POOL, false, false);  // WETH -> DAI
        
        bytes memory executorData = abi.encode(pools);
        (uint256[] memory decodedPools) = abi.decode(executorData, (uint256[]));
        
        assertEq(decodedPools.length, 2, "Should decode two pools correctly");
        assertEq(decodedPools[0], pools[0], "First pool should match");
        assertEq(decodedPools[1], pools[1], "Second pool should match");
    }
    
    function testThreePoolEncoding() public {
        uint256[] memory pools = new uint256[](3);
        pools[0] = _buildV3Pool(USDC_USDT_V3_POOL, true, false);  // USDC -> USDT (assuming)
        pools[1] = _buildV3Pool(USDC_WETH_V3_POOL, true, false);  // USDT -> WETH (via USDC)
        pools[2] = _buildV3Pool(DAI_WETH_V3_POOL, false, true);   // WETH -> DAI with ETH unwrap
        
        bytes memory executorData = abi.encode(pools);
        (uint256[] memory decodedPools) = abi.decode(executorData, (uint256[]));
        
        assertEq(decodedPools.length, 3, "Should decode three pools correctly");
        
        // Verify each pool
        for (uint i = 0; i < 3; i++) {
            assertEq(decodedPools[i], pools[i], string(abi.encodePacked("Pool ", vm.toString(i), " should match")));
        }
    }
    
    // ========== Callback Data Tests ==========
    
    function testCallbackDataEncoding() public {
        uint256[] memory pools = new uint256[](2);
        pools[0] = _buildV3Pool(USDC_WETH_V3_POOL, true, false);
        pools[1] = _buildV3Pool(DAI_WETH_V3_POOL, false, false);
        
        uint256 poolIndex = 1;
        address receiver = user;
        bool isPreview = false;
        
        bytes memory callbackData = abi.encode(pools, poolIndex, receiver, isPreview);
        
        // Decode and verify
        (
            uint256[] memory decodedPools,
            uint256 decodedIndex,
            address decodedReceiver,
            bool decodedIsPreview
        ) = abi.decode(callbackData, (uint256[], uint256, address, bool));
        
        assertEq(decodedPools.length, 2, "Should decode pools correctly");
        assertEq(decodedIndex, poolIndex, "Pool index should match");
        assertEq(decodedReceiver, receiver, "Receiver should match");
        assertEq(decodedIsPreview, isPreview, "IsPreview flag should match");
    }
    
    function testCallbackDataWithPreview() public {
        uint256[] memory pools = new uint256[](1);
        pools[0] = _buildV3Pool(USDC_WETH_V3_POOL, false, false);
        
        bytes memory callbackData = abi.encode(pools, 0, user, true);
        
        (,, , bool isPreview) = abi.decode(callbackData, (uint256[], uint256, address, bool));
        assertTrue(isPreview, "Preview flag should be true");
    }
    
    // ========== Amount Calculation Tests ==========
    
    function testPositiveAmountExtraction() public {
        int256 amount0 = 1000000; // 1 USDC (positive)
        int256 amount1 = -500000000000000000; // -0.5 WETH (negative)
        
        uint256 amountToPay = amount0 > 0 ? uint256(amount0) : uint256(amount1);
        uint256 amountToReceive = amount0 < 0 ? uint256(-amount0) : uint256(-amount1);
        
        assertEq(amountToPay, 1000000, "Should extract positive amount correctly");
        assertEq(amountToReceive, 500000000000000000, "Should extract absolute value of negative amount");
    }
    
    function testNegativeAmountExtraction() public {
        int256 amount0 = -2000000; // -2 USDC (negative)
        int256 amount1 = 1000000000000000000; // 1 WETH (positive)
        
        uint256 amountToPay = amount0 > 0 ? uint256(amount0) : uint256(amount1);
        uint256 amountToReceive = amount0 < 0 ? uint256(-amount0) : uint256(-amount1);
        
        assertEq(amountToPay, 1000000000000000000, "Should use positive amount for payment");
        assertEq(amountToReceive, 2000000, "Should extract absolute value for receipt");
    }
    
    // ========== Sqrt Price Limit Tests ==========
    
    function testSqrtPriceLimits() public {
        assertTrue(_MIN_SQRT_RATIO > 0, "Min sqrt ratio should be positive");
        assertTrue(_MAX_SQRT_RATIO > _MIN_SQRT_RATIO, "Max should be greater than min");
        
        // Test that limits are reasonable for Uniswap V3
        assertTrue(_MIN_SQRT_RATIO >= 4295128740, "Min sqrt ratio should be at minimum threshold");
        assertTrue(_MAX_SQRT_RATIO <= type(uint160).max, "Max sqrt ratio should fit in uint160");
    }
    
    function testSqrtPriceSelection() public {
        // Test price limit selection logic (from _swap function)
        bool zeroForOne = true;
        uint160 sqrtPriceLimitX96 = zeroForOne ? _MIN_SQRT_RATIO : _MAX_SQRT_RATIO;
        assertEq(sqrtPriceLimitX96, _MIN_SQRT_RATIO, "Should use min ratio for zeroForOne=true");
        
        zeroForOne = false;
        sqrtPriceLimitX96 = zeroForOne ? _MIN_SQRT_RATIO : _MAX_SQRT_RATIO;
        assertEq(sqrtPriceLimitX96, _MAX_SQRT_RATIO, "Should use max ratio for zeroForOne=false");
    }
    
    // ========== Edge Cases and Error Conditions ==========
    
    function testEmptyPoolsArray() public {
        uint256[] memory pools = new uint256[](0);
        bytes memory executorData = abi.encode(pools);
        
        (uint256[] memory decodedPools) = abi.decode(executorData, (uint256[]));
        assertEq(decodedPools.length, 0, "Empty pools array should encode/decode correctly");
    }
    
    function testMaxPoolsArray() public {
        // Test with a reasonable number of pools (5 hops)
        uint256[] memory pools = new uint256[](5);
        for (uint i = 0; i < 5; i++) {
            pools[i] = _buildV3Pool(USDC_WETH_V3_POOL, i % 2 == 0, i == 4);
        }
        
        bytes memory executorData = abi.encode(pools);
        (uint256[] memory decodedPools) = abi.decode(executorData, (uint256[]));
        
        assertEq(decodedPools.length, 5, "Should handle multiple pools correctly");
        
        // Verify flags are set correctly
        for (uint i = 0; i < 5; i++) {
            bool zeroForOne = (decodedPools[i] & _ONE_FOR_ZERO_MASK) == 0;
            bool shouldUnwrap = (decodedPools[i] & _WETH_UNWRAP_MASK) != 0;
            
            assertEq(zeroForOne, i % 2 == 0, string(abi.encodePacked("Pool ", vm.toString(i), " zeroForOne flag")));
            assertEq(shouldUnwrap, i == 4, string(abi.encodePacked("Pool ", vm.toString(i), " unwrap flag")));
        }
    }
    
    function testAllFlagsCombinations() public {
        // Test all combinations of flags
        uint256[4] memory testCases = [
            _buildV3Pool(USDC_WETH_V3_POOL, false, false), // no flags
            _buildV3Pool(USDC_WETH_V3_POOL, true, false),  // zeroForOne only
            _buildV3Pool(USDC_WETH_V3_POOL, false, true),  // unwrap only  
            _buildV3Pool(USDC_WETH_V3_POOL, true, true)    // both flags
        ];
        
        bool[4] memory expectedZeroForOne = [false, true, false, true];
        bool[4] memory expectedUnwrap = [false, false, true, true];
        
        for (uint i = 0; i < 4; i++) {
            bool zeroForOne = (testCases[i] & _ONE_FOR_ZERO_MASK) == 0;
            bool unwrap = (testCases[i] & _WETH_UNWRAP_MASK) != 0;
            
            assertEq(zeroForOne, expectedZeroForOne[i], string(abi.encodePacked("Case ", vm.toString(i), " zeroForOne")));
            assertEq(unwrap, expectedUnwrap[i], string(abi.encodePacked("Case ", vm.toString(i), " unwrap")));
        }
    }
    
    // ========== Helper Functions ==========
    
    /// @notice Build V3 pool data with flags
    /// @param pool The pool address
    /// @param zeroForOne Whether the swap is token0 -> token1
    /// @param unwrapETH Whether to unwrap WETH to ETH
    /// @return poolData Encoded pool data
    function _buildV3Pool(
        address pool,
        bool zeroForOne,
        bool unwrapETH
    ) internal pure returns (uint256) {
        uint256 poolData = uint256(uint160(pool));
        
        if (zeroForOne) {
            poolData |= _ONE_FOR_ZERO_MASK;
        }
        
        if (unwrapETH) {
            poolData |= _WETH_UNWRAP_MASK;
        }
        
        return poolData;
    }
    
    /// @notice Convert uint256 to address
    /// @param value The uint256 value
    /// @return addr The address
    function _bytes32ToAddress(uint256 value) internal pure returns (address addr) {
        return address(uint160(value));
    }
}

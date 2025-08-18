// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";

import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/interfaces/IWETH.sol";
import "@dex/interfaces/IUniswapV2Factory.sol";
import "@dex/interfaces/IUniswapV2Pair.sol";
import "@dex/interfaces/IERC20.sol";

import {UniV3ExactOutExecutor} from "@dex/executor/UniV3ExactOutExecutor.sol";

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
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // Uniswap V3 pool addresses
    address constant USDC_WETH_V3_POOL = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // 0.05% fee
    address constant DAI_WETH_V3_POOL = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;   // 0.3% fee
    address constant USDC_USDT_V3_POOL = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6;  // 0.01% fee
    
    address user = makeAddr("user");
    UniV3ExactOutExecutor executor;
    DexRouter dexRouter;
    TokenApprove tokenApprove;
    TokenApproveProxy tokenApproveProxy;
    WNativeRelayer wNativeRelayer;
    
    function setUp() public {
        // Fork Ethereum mainnet for realistic pool addresses
        vm.createSelectFork("eth", 18500000);        
        // Deploy executor
        executor = new UniV3ExactOutExecutor();
        
        // Deploy DexRouter
        dexRouter = new DexRouter();
        
        // Use existing mainnet contracts
        tokenApprove = TokenApprove(0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f);
        tokenApproveProxy = TokenApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58);
        wNativeRelayer = WNativeRelayer(payable(0x5703B683c7F928b721CA95Da988d73a3299d4757));
        
        // Add DexRouter to TokenApproveProxy whitelist
        address tokenApproveProxyOwner = tokenApproveProxy.owner();
        vm.startPrank(tokenApproveProxyOwner);
        tokenApproveProxy.addProxy(address(dexRouter));
        vm.stopPrank();
        
        // Add DexRouter to WNativeRelayer whitelist
        address wNativeRelayerOwner = wNativeRelayer.owner();
        vm.startPrank(wNativeRelayerOwner);
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
        
    }

    function test_swap_USDC_WETH_V3() public {
        deal(USDC, address(this), 4800000 * 10**6);
        IERC20(USDC).approve(address(tokenApprove), type(uint256).max);
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: _addressToUint256(USDC),
            toToken: WETH,
            fromTokenAmount: 4800 * 10**6,
            minReturnAmount: 0,
            deadLine: block.timestamp + 1000
        });
        uint256[] memory pools = new uint256[](1);  
        pools[0] =  _encodePool(USDC_WETH_V3_POOL, true, false);
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: address(executor),
            toTokenExpectedAmount: 1 ether,
            maxConsumeAmount: 4800 * 10**6,
            executorData: abi.encode(pools)
        });
        dexRouter.executeWithBaseRequest(1, address(user), baseRequest, address(executor), executorInfo);

    }
    function test_swap_USDC_ETH_V3() public {
        deal(USDC, address(this), 4800000 * 10**6);
        IERC20(USDC).approve(address(tokenApprove), type(uint256).max);
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: _addressToUint256(USDC),
            toToken: ETH,
            fromTokenAmount: 4800 * 10**6,
            minReturnAmount: 0,
            deadLine: block.timestamp + 1000
        });
        uint256[] memory pools = new uint256[](1);  
        pools[0] =  _encodePool(USDC_WETH_V3_POOL, true, true);
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: address(executor),
            toTokenExpectedAmount: 1 ether,
            maxConsumeAmount: 4800 * 10**6,
            executorData: abi.encode(pools)
        });
        dexRouter.executeWithBaseRequest(1, address(user), baseRequest, address(executor), executorInfo);

    }

    function test_swap_USDC_WETH_DAI_V3() public {
        deal(USDC, address(this), 4800000 * 10**6);
        IERC20(USDC).approve(address(tokenApprove), type(uint256).max);
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: _addressToUint256(USDC),
            toToken: DAI,
            fromTokenAmount: 4800 * 10**6,
            minReturnAmount: 0,
            deadLine: block.timestamp + 1000
        });
        uint256[] memory pools = new uint256[](2);  
        pools[0] =  _encodePool(USDC_WETH_V3_POOL, true, false);
        pools[1] =  _encodePool(DAI_WETH_V3_POOL, false, false);
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: address(executor),
            toTokenExpectedAmount: 1 ether,
            maxConsumeAmount: 4800 * 10**6,
            executorData: abi.encode(pools)
        });
        dexRouter.executeWithBaseRequest(1, address(user), baseRequest, address(executor), executorInfo);
    }


    function _addressToUint256(address addr) internal pure returns (uint256) {
        return uint256(uint160(addr));
    }
    function _encodePool(address pool, bool zeroForOne, bool isETH) internal pure returns (uint256) {
        return uint256(uint160(pool)) | (zeroForOne ? 0 : _ONE_FOR_ZERO_MASK) | (isETH ? _WETH_MASK : 0);
    }
    
    
}

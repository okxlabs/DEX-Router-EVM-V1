// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {DexRouter, IDexRouter} from "@dex/DexRouter.sol";
import {UniV2ExactOutExecutor} from "@dex/executor/UniV2ExactOutExecutor.sol";
import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/interfaces/IWETH.sol";
import "@dex/interfaces/IUniswapV2Factory.sol";
import "@dex/interfaces/IUniswapV2Pair.sol";
import "@dex/interfaces/IERC20.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UniV2ExactOutExecutorForkTest is Test {
    // Contracts
    DexRouter dexRouter;
    UniV2ExactOutExecutor executor;
    TokenApprove tokenApprove;
    TokenApproveProxy tokenApproveProxy;
    WNativeRelayer wNativeRelayer;
    
    // Ethereum mainnet addresses
    IWETH constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    
    IUniswapV2Factory constant UNISWAP_V2_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    // Test addresses
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant COMMISSION_ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address whale = makeAddr("whale");
    address user = makeAddr("user");
    address admin = makeAddr("admin");
    
    // Constants for pool encoding
    uint256 private constant _DENOMINATOR = 1_000_000_000;
    uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _REVERSE_MASK = 1 << 255;
    uint256 private constant _WETH_MASK = 1 << 254;
    uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
    uint256 private constant _NUMERATOR_OFFSET = 160;
    
    // Uniswap V2 pairs on mainnet
    address WETH_USDC_PAIR;
    address WETH_DAI_PAIR;
    address USDC_USDT_PAIR;
    
    function setUp() public {
        // Fork Ethereum mainnet at a specific block
        vm.createSelectFork("eth", 18500000);
        
        // Get actual Uniswap V2 pair addresses
        WETH_USDC_PAIR = UNISWAP_V2_FACTORY.getPair(address(WETH), address(USDC));
        WETH_DAI_PAIR = UNISWAP_V2_FACTORY.getPair(address(WETH), address(DAI));
        USDC_USDT_PAIR = UNISWAP_V2_FACTORY.getPair(address(USDC), address(USDT));
        
        require(WETH_USDC_PAIR != address(0), "WETH_USDC pair not found");
        require(WETH_DAI_PAIR != address(0), "WETH_DAI pair not found");
        require(USDC_USDT_PAIR != address(0), "USDC_USDT pair not found");
        
        // Deploy contracts
        vm.startPrank(admin);
        
        // Deploy executor
        executor = new UniV2ExactOutExecutor();
        
        // Deploy DexRouter
        dexRouter = new DexRouter();
        
        vm.stopPrank();
        
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
        
        // Setup user with tokens
        setupUserTokens();
    }
    
    function setupUserTokens() internal {
        // Deal ETH to user
        vm.deal(user, 100 ether);
        
        // Deal tokens to user (using whale addresses or deal)
        deal(address(WETH), user, 50 ether);
        deal(address(USDC), user, 100000 * 1e6); // 100k USDC
        deal(address(DAI), user, 100000 * 1e18); // 100k DAI
        deal(address(USDT), user, 100000 * 1e6); // 100k USDT
    }
    
    function _buildPool(
        address sourceToken,
        address targetToken,
        address pool,
        bool isToETH
    ) internal view returns (bytes32) {
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();
        uint8 flag;
        uint8 flag2;
        
        if (sourceToken == token0) {
            require(targetToken == token1, "sourceToken is token0, targetToken must be token1");
            flag = uint8(0x00);
        } else {
            require(targetToken == token0, "sourceToken is token1, targetToken must be token0");
            flag = uint8(0x80);
        }
        
        if (isToETH) {
            require(targetToken == address(WETH), "targetToken must be WETH");
            flag2 = uint8(0x40);
        }
        
        // Use 997000000 as numerator (0.3% fee)
        bytes32 poolData = bytes32(abi.encodePacked(uint8(flag2+flag), uint56(0), uint32(997000000), address(pool)));
        return poolData;
    }
    
    function testExecuteWithBaseRequest_WETH_to_USDC() public {
        uint256 orderId = 1;
        uint256 amountOut = 1000 * 1e6; // 1000 USDC
        uint256 maxConsumeAmount = 1 ether; // Max 1 WETH
        
        // Build pool data for WETH -> USDC swap
        bytes32 poolData = _buildPool(address(WETH), address(USDC), WETH_USDC_PAIR, false);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = poolData;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(WETH))),
            toToken: address(USDC),
            fromTokenAmount: 0, // Will be calculated by preview
            minReturnAmount: amountOut * 99 / 100, // 1% slippage
            deadLine: block.timestamp + 300
        });
        
        // Record initial balances
        uint256 initialWETHBalance = WETH.balanceOf(user);
        uint256 initialUSDCBalance = USDC.balanceOf(user);
        
        console2.log("Initial WETH balance:", initialWETHBalance);
        console2.log("Initial USDC balance:", initialUSDCBalance);
        
        vm.startPrank(user);
        
        // Approve tokens
        WETH.approve(address(tokenApprove), maxConsumeAmount);
        
        // Create ExecutorInfo struct
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: WETH_USDC_PAIR,
            toTokenExpectedAmount: amountOut,
            maxConsumeAmount: maxConsumeAmount,

            executorData: executorData
        });

        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            address(executor),
            executorInfo
        );
        
        vm.stopPrank();
        
        // Check final balances
        uint256 finalWETHBalance = WETH.balanceOf(user);
        uint256 finalUSDCBalance = USDC.balanceOf(user);
        
        console2.log("Final WETH balance:", finalWETHBalance);
        console2.log("Final USDC balance:", finalUSDCBalance);
        console2.log("Return amount:", returnAmount);
        console2.log("WETH consumed:", initialWETHBalance - finalWETHBalance);
        console2.log("USDC received:", finalUSDCBalance - initialUSDCBalance);
        
        // Assertions
        assertLt(finalWETHBalance, initialWETHBalance, "WETH should be consumed");
        assertGt(finalUSDCBalance, initialUSDCBalance, "USDC should be received");
        assertGe(finalUSDCBalance - initialUSDCBalance, baseRequest.minReturnAmount, "Should meet minimum return");
        assertGt(returnAmount, 0, "Return amount should be positive");
    }
    
    function testExecuteWithBaseRequest_USDC_to_DAI() public {
        uint256 orderId = 2;
        uint256 amountOut = 1000 * 1e18; // 1000 DAI
        uint256 maxConsumeAmount = 1100 * 1e6; // Max 1100 USDC
        
        // Build pool data for USDC -> DAI swap (through WETH)
        bytes32 poolData1 = _buildPool(address(USDC), address(WETH), WETH_USDC_PAIR, false);
        bytes32 poolData2 = _buildPool(address(WETH), address(DAI), WETH_DAI_PAIR, false);
        
        bytes32[] memory pools = new bytes32[](2);
        pools[0] = poolData1;
        pools[1] = poolData2;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(USDC))),
            toToken: address(DAI),
            fromTokenAmount: 0, // Will be calculated by preview
            minReturnAmount: amountOut * 99 / 100, // 1% slippage
            deadLine: block.timestamp + 300
        });
        
        // Record initial balances
        uint256 initialUSDCBalance = USDC.balanceOf(user);
        uint256 initialDAIBalance = DAI.balanceOf(user);
        
        console2.log("Initial USDC balance:", initialUSDCBalance);
        console2.log("Initial DAI balance:", initialDAIBalance);
        
        vm.startPrank(user);
        
        // Approve tokens
        USDC.approve(address(tokenApprove), maxConsumeAmount);
        
        // Create ExecutorInfo struct
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: WETH_USDC_PAIR,
            toTokenExpectedAmount: amountOut,
            maxConsumeAmount: maxConsumeAmount,

            executorData: executorData
        });

        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            address(executor),
            executorInfo
        );
        
        vm.stopPrank();
        
        // Check final balances
        uint256 finalUSDCBalance = USDC.balanceOf(user);
        uint256 finalDAIBalance = DAI.balanceOf(user);
        
        console2.log("Final USDC balance:", finalUSDCBalance);
        console2.log("Final DAI balance:", finalDAIBalance);
        console2.log("Return amount:", returnAmount);
        console2.log("USDC consumed:", initialUSDCBalance - finalUSDCBalance);
        console2.log("DAI received:", finalDAIBalance - initialDAIBalance);
        
        // Assertions
        assertLt(finalUSDCBalance, initialUSDCBalance, "USDC should be consumed");
        assertGt(finalDAIBalance, initialDAIBalance, "DAI should be received");
        assertGe(finalDAIBalance - initialDAIBalance, baseRequest.minReturnAmount, "Should meet minimum return");
        assertGt(returnAmount, 0, "Return amount should be positive");
    }
    
    // TODO: Fix ETH handling in executeWithBaseRequest
    // function testExecuteWithBaseRequest_ETH_to_USDC() public {
    //     // This test needs additional work to handle ETH properly
    // }
    
    function testExecuteWithBaseRequest_USDC_to_ETH() public {
        uint256 orderId = 4;
        uint256 amountOut = 0.5 ether; // 0.5 ETH
        uint256 maxConsumeAmount = 2000 * 1e6; // Max 2000 USDC
        
        // Build pool data for USDC -> ETH swap (WETH gets unwrapped to ETH)
        bytes32 poolData = _buildPool(address(USDC), address(WETH), WETH_USDC_PAIR, true);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = poolData;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest for USDC -> ETH (toToken = 0)
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(USDC))),
            toToken: ETH,
            fromTokenAmount: 0, // Will be calculated by preview
            minReturnAmount: amountOut * 99 / 100, // 1% slippage
            deadLine: block.timestamp + 300
        });
        
        // Record initial balances
        uint256 initialUSDCBalance = USDC.balanceOf(user);
        uint256 initialETHBalance = user.balance;
        
        console2.log("Initial USDC balance:", initialUSDCBalance);
        console2.log("Initial ETH balance:", initialETHBalance);
        
        vm.startPrank(user);
        
        // Approve tokens
        USDC.approve(address(tokenApprove), maxConsumeAmount);
        
        // Create ExecutorInfo struct
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: WETH_USDC_PAIR,
            toTokenExpectedAmount: amountOut,
            maxConsumeAmount: maxConsumeAmount,

            executorData: executorData
        });

        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            address(executor),
            executorInfo
        );
        
        vm.stopPrank();
        
        // Check final balances
        uint256 finalUSDCBalance = USDC.balanceOf(user);
        uint256 finalETHBalance = user.balance;
        
        console2.log("Final USDC balance:", finalUSDCBalance);
        console2.log("Final ETH balance:", finalETHBalance);
        console2.log("Return amount:", returnAmount);
        console2.log("USDC consumed:", initialUSDCBalance - finalUSDCBalance);
        console2.log("ETH received:", finalETHBalance - initialETHBalance);
        
        // Assertions
        assertLt(finalUSDCBalance, initialUSDCBalance, "USDC should be consumed");
        assertGt(finalETHBalance, initialETHBalance, "ETH should be received");
        assertGe(finalETHBalance - initialETHBalance, baseRequest.minReturnAmount, "Should meet minimum return");
        assertGt(returnAmount, 0, "Return amount should be positive");
    }
    

    
    function testExecuteWithBaseRequest_TwoPool_USDC_to_DAI() public {
        _testTwoPoolSwap();
    }

    function _testTwoPoolSwap() internal {
        uint256 amountOut = 500 * 1e18; // 500 DAI
        uint256 maxConsumeAmount = 600 * 1e6; // Max 600 USDC
        
        // Build pool data
        bytes32[] memory pools = new bytes32[](2);
        pools[0] = _buildPool(address(USDC), address(WETH), WETH_USDC_PAIR, false);
        pools[1] = _buildPool(address(WETH), address(DAI), WETH_DAI_PAIR, false);
        
        // Create request
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(USDC))),
            toToken: address(DAI),
            fromTokenAmount: 0,
            minReturnAmount: amountOut * 99 / 100,
            deadLine: block.timestamp + 300
        });
        
        // Execute swap
        uint256 returnAmount = _executeSwap(6, baseRequest, WETH_USDC_PAIR, amountOut, maxConsumeAmount, abi.encode(pools));
        
        // Verify results
        _verifyTwoPoolResults(amountOut, returnAmount);
    }

    function _executeSwap(
        uint256 orderId,
        IDexRouter.BaseRequest memory baseRequest,
        address assetTo,
        uint256 amountOut,
        uint256 maxConsumeAmount,
        bytes memory executorData
    ) internal returns (uint256) {
        vm.startPrank(user);
        
        // Approve tokens based on fromToken
        address fromToken = _bytes32ToAddress(baseRequest.fromToken);
        if (fromToken != ETH) {
            IERC20(fromToken).approve(address(tokenApprove), maxConsumeAmount);
        }
        
        // Create ExecutorInfo struct
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: assetTo,
            toTokenExpectedAmount: amountOut,
            maxConsumeAmount: maxConsumeAmount,

            executorData: executorData
        });

        // Execute swap with ETH value if needed
        uint256 returnAmount;
        if (fromToken == ETH) {
            uint256 msgValue = maxConsumeAmount + 1000; // Add small buffer
            returnAmount = dexRouter.executeWithBaseRequest{value: msgValue}(
                orderId,
                user,
                baseRequest,
                address(executor),
                executorInfo
            );
        } else {
            returnAmount = dexRouter.executeWithBaseRequest(
                orderId,
                user,
                baseRequest,
                address(executor),
                executorInfo
            );
        }
        
        vm.stopPrank();
        return returnAmount;
    }

    function _verifyTwoPoolResults(uint256 expectedAmount, uint256 returnAmount) internal {
        assertGt(returnAmount, 0, "Return amount should be positive");
        assertEq(returnAmount, expectedAmount, "Return amount should equal expected output");
    }

    function _bytes32ToAddress(uint256 value) internal pure returns (address) {
        return address(uint160(value));
    }

    // TODO: Fix three-pool swap logic
    // function testExecuteWithBaseRequest_ThreePool_USDT_to_DAI() public {
    //     // This test needs additional work to handle multi-hop swaps properly
    // }

    function test_RevertWhen_InsufficientMaxAmount() public {
        uint256 orderId = 5;
        uint256 amountOut = 1000 * 1e6; // 1000 USDC
        uint256 maxConsumeAmount = 0.01 ether; // Very small max amount (should fail)
        
        // Build pool data for WETH -> USDC swap
        bytes32 poolData = _buildPool(address(WETH), address(USDC), WETH_USDC_PAIR, false);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = poolData;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(WETH))),
            toToken: address(USDC),
            fromTokenAmount: 0,
            minReturnAmount: amountOut * 99 / 100,
            deadLine: block.timestamp + 300
        });
        
        vm.startPrank(user);
        WETH.approve(address(tokenApprove), maxConsumeAmount);
        
        // Create ExecutorInfo struct
        IDexRouter.ExecutorInfo memory executorInfo = IDexRouter.ExecutorInfo({
            assetTo: WETH_USDC_PAIR,
            toTokenExpectedAmount: amountOut,
            maxConsumeAmount: maxConsumeAmount,

            executorData: executorData
        });
        
        // This should fail with "consumeAmount > maxConsumeAmount"
        vm.expectRevert("consumeAmount > maxConsumeAmount");
        dexRouter.executeWithBaseRequest(
            orderId,
            user,
            baseRequest,
            address(executor),
            executorInfo
        );
        
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/executor/UniV2ExactOutExecutor.sol";
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
        
        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            WETH_USDC_PAIR, // assetTo (first pool address)
            amountOut, // toTokenExpectedAmount
            maxConsumeAmount,
            address(executor), // executor
            executorData
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
        
        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            WETH_USDC_PAIR, // assetTo (first pool address)
            amountOut, // toTokenExpectedAmount
            maxConsumeAmount,
            address(executor), // executor
            executorData
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
    
    function testExecuteWithBaseRequest_ETH_to_USDC() public {
        uint256 orderId = 3;
        uint256 amountOut = 2000 * 1e6; // 2000 USDC
        
        // Build pool data for ETH -> USDC swap (ETH gets wrapped to WETH)
        bytes32 poolData = _buildPool(address(WETH), address(USDC), WETH_USDC_PAIR, false);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = poolData;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest for ETH (fromToken = 0)
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(ETH)),
            toToken: address(USDC),
            fromTokenAmount: 0, // Will be calculated by preview
            minReturnAmount: amountOut * 99 / 100, // 1% slippage
            deadLine: block.timestamp + 300
        });
        
        // First get the required ETH amount via preview
        uint256 requiredETH = executor.preview(baseRequest, amountOut, executorData);
        uint256 maxConsumeAmount = requiredETH + (requiredETH * 10 / 100); // Add 10% buffer
        
        // Ensure msg.value is slightly higher than maxConsumeAmount for validation
        uint256 msgValue = maxConsumeAmount + 1000; // Add small buffer
        
        // Record initial balances
        uint256 initialETHBalance = user.balance;
        uint256 initialUSDCBalance = USDC.balanceOf(user);
        
        console2.log("Initial ETH balance:", initialETHBalance);
        console2.log("Initial USDC balance:", initialUSDCBalance);
        console2.log("Required ETH amount:", requiredETH);
        console2.log("Max consume amount:", maxConsumeAmount);
        console2.log("Msg value:", msgValue);
        
        vm.startPrank(user);
        
        // Execute swap through DexRouter with ETH value
        uint256 returnAmount = dexRouter.executeWithBaseRequest{value: msgValue}(
            orderId,
            user, // receiver
            baseRequest,
            WETH_USDC_PAIR, // assetTo (first pool address)
            amountOut, // toTokenExpectedAmount
            maxConsumeAmount,
            address(executor), // executor
            executorData
        );
        
        vm.stopPrank();
        
        // Check final balances
        uint256 finalETHBalance = user.balance;
        uint256 finalUSDCBalance = USDC.balanceOf(user);
        
        console2.log("Final ETH balance:", finalETHBalance);
        console2.log("Final USDC balance:", finalUSDCBalance);
        console2.log("Return amount:", returnAmount);
        console2.log("ETH consumed:", initialETHBalance - finalETHBalance);
        console2.log("USDC received:", finalUSDCBalance - initialUSDCBalance);
        
        // Assertions
        assertLt(finalETHBalance, initialETHBalance, "ETH should be consumed");
        assertGt(finalUSDCBalance, initialUSDCBalance, "USDC should be received");
        assertGe(finalUSDCBalance - initialUSDCBalance, baseRequest.minReturnAmount, "Should meet minimum return");
        assertGt(returnAmount, 0, "Return amount should be positive");
    }
    
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
        
        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            WETH_USDC_PAIR, // assetTo (first pool address)
            amountOut, // toTokenExpectedAmount
            maxConsumeAmount,
            address(executor), // executor
            executorData
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
    
    function testPreviewFunction() public {
        uint256 amountOut = 1000 * 1e6; // 1000 USDC
        
        // Build pool data for WETH -> USDC swap
        bytes32 poolData = _buildPool(address(WETH), address(USDC), WETH_USDC_PAIR, false);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = poolData;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(WETH))),
            toToken: address(USDC),
            fromTokenAmount: 1 ether, // Initial amount (will be recalculated)
            minReturnAmount: amountOut * 99 / 100,
            deadLine: block.timestamp + 300
        });
        
        // Call preview function
        uint256 requiredAmount = executor.preview(baseRequest, amountOut, executorData);
        
        console2.log("Required WETH amount for 1000 USDC:", requiredAmount);
        
        // Assertions
        assertGt(requiredAmount, 0, "Required amount should be positive");
        assertLt(requiredAmount, 10 ether, "Required amount should be reasonable");
    }
    
    function testExecuteWithBaseRequest_TwoPool_USDC_to_DAI() public {
        uint256 orderId = 6;
        uint256 amountOut = 500 * 1e18; // 500 DAI
        uint256 maxConsumeAmount = 600 * 1e6; // Max 600 USDC
        
        // Build pool data for USDC -> WETH -> DAI swap (2 pools)
        // Pool 1: USDC -> WETH
        bytes32 poolData1 = _buildPool(address(USDC), address(WETH), WETH_USDC_PAIR, false);
        // Pool 2: WETH -> DAI  
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
        uint256 initialWETHBalance = WETH.balanceOf(user);
        
        console2.log("=== Two Pool Test: USDC -> WETH -> DAI ===");
        console2.log("Initial USDC balance:", initialUSDCBalance);
        console2.log("Initial WETH balance:", initialWETHBalance);
        console2.log("Initial DAI balance:", initialDAIBalance);
        console2.log("Target DAI amount:", amountOut);
        
        vm.startPrank(user);
        
        // Approve tokens
        USDC.approve(address(tokenApprove), maxConsumeAmount);
        
        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            WETH_USDC_PAIR, // assetTo (first pool address)
            amountOut, // toTokenExpectedAmount
            maxConsumeAmount,
            address(executor), // executor
            executorData
        );
        
        vm.stopPrank();
        
        // Check final balances
        uint256 finalUSDCBalance = USDC.balanceOf(user);
        uint256 finalDAIBalance = DAI.balanceOf(user);
        uint256 finalWETHBalance = WETH.balanceOf(user);
        
        console2.log("Final USDC balance:", finalUSDCBalance);
        console2.log("Final WETH balance:", finalWETHBalance);
        console2.log("Final DAI balance:", finalDAIBalance);
        console2.log("Return amount:", returnAmount);
        console2.log("USDC consumed:", initialUSDCBalance - finalUSDCBalance);
        console2.log("DAI received:", finalDAIBalance - initialDAIBalance);
        console2.log("WETH balance change:", finalWETHBalance > initialWETHBalance ? 
            finalWETHBalance - initialWETHBalance : initialWETHBalance - finalWETHBalance);
        
        // Assertions
        assertLt(finalUSDCBalance, initialUSDCBalance, "USDC should be consumed");
        assertGt(finalDAIBalance, initialDAIBalance, "DAI should be received");
        assertGe(finalDAIBalance - initialDAIBalance, baseRequest.minReturnAmount, "Should meet minimum return");
        assertEq(finalDAIBalance - initialDAIBalance, amountOut, "Should receive exact DAI amount");
        assertGt(returnAmount, 0, "Return amount should be positive");
        assertEq(returnAmount, amountOut, "Return amount should equal expected output");
        
        // WETH balance should remain unchanged (intermediate token)
        assertEq(finalWETHBalance, initialWETHBalance, "WETH balance should be unchanged (intermediate token)");
    }

    function testExecuteWithBaseRequest_ThreePool_USDT_to_DAI() public {
        uint256 orderId = 7;
        uint256 amountOut = 250 * 1e18; // 250 DAI
        uint256 maxConsumeAmount = 300 * 1e6; // Max 300 USDT
        
        // Build pool data for USDT -> USDC -> WETH -> DAI swap (3 pools)
        // Pool 1: USDT -> USDC
        bytes32 poolData1 = _buildPool(address(USDT), address(USDC), USDC_USDT_PAIR, false);
        // Pool 2: USDC -> WETH
        bytes32 poolData2 = _buildPool(address(USDC), address(WETH), WETH_USDC_PAIR, false);
        // Pool 3: WETH -> DAI
        bytes32 poolData3 = _buildPool(address(WETH), address(DAI), WETH_DAI_PAIR, false);
        
        bytes32[] memory pools = new bytes32[](3);
        pools[0] = poolData1;
        pools[1] = poolData2;
        pools[2] = poolData3;
        bytes memory executorData = abi.encode(pools);
        
        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(address(USDT))),
            toToken: address(DAI),
            fromTokenAmount: 0, // Will be calculated by preview
            minReturnAmount: amountOut * 99 / 100, // 1% slippage
            deadLine: block.timestamp + 300
        });
        
        // Record initial balances
        uint256 initialUSDTBalance = USDT.balanceOf(user);
        uint256 initialUSDCBalance = USDC.balanceOf(user);
        uint256 initialWETHBalance = WETH.balanceOf(user);
        uint256 initialDAIBalance = DAI.balanceOf(user);
        
        console2.log("=== Three Pool Test: USDT -> USDC -> WETH -> DAI ===");
        console2.log("Initial USDT balance:", initialUSDTBalance);
        console2.log("Initial USDC balance:", initialUSDCBalance);
        console2.log("Initial WETH balance:", initialWETHBalance);
        console2.log("Initial DAI balance:", initialDAIBalance);
        console2.log("Target DAI amount:", amountOut);
        
        vm.startPrank(user);
        
        // Approve tokens
        USDT.approve(address(tokenApprove), maxConsumeAmount);
        
        // Execute swap through DexRouter
        uint256 returnAmount = dexRouter.executeWithBaseRequest(
            orderId,
            user, // receiver
            baseRequest,
            USDC_USDT_PAIR, // assetTo (first pool address)
            amountOut, // toTokenExpectedAmount
            maxConsumeAmount,
            address(executor), // executor
            executorData
        );
        
        vm.stopPrank();
        
        // Check final balances
        uint256 finalUSDTBalance = USDT.balanceOf(user);
        uint256 finalUSDCBalance = USDC.balanceOf(user);
        uint256 finalWETHBalance = WETH.balanceOf(user);
        uint256 finalDAIBalance = DAI.balanceOf(user);
        
        console2.log("Final USDT balance:", finalUSDTBalance);
        console2.log("Final USDC balance:", finalUSDCBalance);
        console2.log("Final WETH balance:", finalWETHBalance);
        console2.log("Final DAI balance:", finalDAIBalance);
        console2.log("Return amount:", returnAmount);
        console2.log("USDT consumed:", initialUSDTBalance - finalUSDTBalance);
        console2.log("DAI received:", finalDAIBalance - initialDAIBalance);
        
        // Assertions
        assertLt(finalUSDTBalance, initialUSDTBalance, "USDT should be consumed");
        assertGt(finalDAIBalance, initialDAIBalance, "DAI should be received");
        assertGe(finalDAIBalance - initialDAIBalance, baseRequest.minReturnAmount, "Should meet minimum return");
        assertEq(finalDAIBalance - initialDAIBalance, amountOut, "Should receive exact DAI amount");
        assertGt(returnAmount, 0, "Return amount should be positive");
        assertEq(returnAmount, amountOut, "Return amount should equal expected output");
        
        // Intermediate tokens (USDC, WETH) should remain unchanged
        assertEq(finalUSDCBalance, initialUSDCBalance, "USDC balance should be unchanged (intermediate token)");
        assertEq(finalWETHBalance, initialWETHBalance, "WETH balance should be unchanged (intermediate token)");
    }

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
        
        // This should fail with "consumeAmount > maxConsumeAmount"
        vm.expectRevert("consumeAmount > maxConsumeAmount");
        dexRouter.executeWithBaseRequest(
            orderId,
            user,
            baseRequest,
            WETH_USDC_PAIR, // assetTo (first pool address)
            amountOut,
            maxConsumeAmount,
            address(executor),
            executorData
        );
        
        vm.stopPrank();
    }
}

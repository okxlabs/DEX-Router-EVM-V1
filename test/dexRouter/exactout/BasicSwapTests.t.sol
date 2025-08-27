// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/BaseTestSetup.t.sol";

contract BasicSwapTests is BaseTestSetup {

    // V2 Tests
    // Test ERC20 token single pool exchange unoswapV2
    function testERC20TokenSinglePoolExchange() public {
        uint256 sourceTokenIndex = 1;
        uint256 targetTokenIndex = 2;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 500e18;

        IUniswapV2Pair pair = IUniswapV2Pair(pairMatrix[1][2]);
        IERC20 sourceToken = IERC20(address(tokens[sourceTokenIndex]));
        IERC20 targetToken = IERC20(address(tokens[targetTokenIndex]));
        console2.log("sourceToken:", address(sourceToken));
        console2.log("targetToken:", address(targetToken));
        console2.log("before sourceToken balance:", sourceToken.balanceOf(amy));
        console2.log("before targetToken balance:", targetToken.balanceOf(amy));
        
        // Build pool data
        bytes32 pool0 = _buildPool(address(sourceToken), address(targetToken), address(pair), false);

        vm.startPrank(amy);
        sourceToken.approve(address(tokenApprove), amountInMax);

        bytes32[] memory pools = new bytes32[](1);
        pools[0] = pool0;

        dexRouterExactOut.unxswapExactOutTo(
            uint256(uint160(address(sourceToken))),
            amountOut,
            amountInMax,
            amy,
            pools
        );
        vm.stopPrank();

        console2.log("after sourceToken balance:", sourceToken.balanceOf(amy));
        console2.log("after targetToken balance:", targetToken.balanceOf(amy));
    }

    // Test ETH token single pool exchange (ETH as source token)
    function testETHTokenSinglePoolInExchange() public {
        uint256 sourceTokenIndex = 0;
        uint256 targetTokenIndex = 1;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 500e18;

        IUniswapV2Pair pair = IUniswapV2Pair(pairMatrix[0][1]);
        console2.log("sourceToken:", address(ETH));
        console2.log("middleToken:", address(tokens[sourceTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        console2.log("before sourceToken balance:", amy.balance);
        console2.log("before middleToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[targetTokenIndex]), address(pair), false);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = pool0;

        vm.startPrank(amy);
            dexRouterExactOut.unxswapExactOutTo{value: amountInMax}(
                uint256(uint160(ETH)),
                amountOut,
                amountInMax,
                amy,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", amy.balance);
        console2.log("after middleToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
    }

    // Test ETH token single pool exchange (ETH as target token)
    function testETHTokenSinglePoolOutExchange() public {
        uint256 sourceTokenIndex = 1;
        uint256 targetTokenIndex = 0;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 500e18;

        IUniswapV2Pair pair = IUniswapV2Pair(pairMatrix[1][0]);
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[targetTokenIndex]));
        console2.log("targetToken:", address(ETH));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[targetTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", amy.balance);

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[targetTokenIndex]), address(pair), true);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = pool0;

        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), amountInMax);
            dexRouterExactOut.unxswapExactOutTo(
                uint256(uint160(address(tokens[sourceTokenIndex]))),
                amountOut,
                amountInMax,
                amy,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[targetTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", amy.balance);
    }

    // V3 Tests
    // unoswapV3: Test ERC20 token single pool exchange
    function testERC20TokenSinglePoolExchangeV3() public {
        uint256 sourceTokenIndex = 1;
        uint256 targetTokenIndex = 2;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 500e18;
        IUniswapV3Pool pair = IUniswapV3Pool(v3PairMatrix[1][2]);
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        
        // Record initial balances
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[targetTokenIndex]), address(pair), false);
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(pool0);

        vm.startPrank(amy);
            // Ensure sufficient approval amount
            tokens[sourceTokenIndex].approve(address(tokenApprove), type(uint256).max);
            dexRouterExactOut.uniswapV3SwapExactOutTo(
                uint256(uint160(amy)), // Convert amy address to uint256 type
                amountOut,
                amountInMax,
                pools
            );
        vm.stopPrank();

        // Record final balances
        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
        
    }
    
    // unoswapV3: Test ETH token single pool exchange (ETH as source token)
    function testETHTokenSinglePoolExchangeV3() public {
        uint256 sourceTokenIndex = 0;
        uint256 targetTokenIndex = 1;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 500e18;
        IUniswapV3Pool pair = IUniswapV3Pool(v3PairMatrix[0][1]);
        console2.log("sourceToken:", address(ETH));
        console2.log("middleToken:", address(tokens[sourceTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        console2.log("before sourceToken balance:", amy.balance);
        console2.log("before middleToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[targetTokenIndex]), address(pair), false);
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(pool0);  
        
        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), type(uint256).max);
            dexRouterExactOut.uniswapV3SwapExactOutTo{value: amountInMax}(
                uint256(uint160(amy)),
                amountOut,
                amountInMax,
                pools); 
        vm.stopPrank();

        console2.log("after sourceToken balance:", amy.balance);
        console2.log("after middleToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
    }

    // unoswapV3: Test ETH token single pool exchange (ETH as target token)
    function testETHTokenSinglePoolExchangeV3Out() public {
        uint256 sourceTokenIndex = 1;
        uint256 targetTokenIndex = 0;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 500e18;
        IUniswapV3Pool pair = IUniswapV3Pool(v3PairMatrix[1][0]);
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[targetTokenIndex]));
        console2.log("targetToken:", address(ETH));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[targetTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", amy.balance);

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[targetTokenIndex]), address(pair), true);
        uint256[] memory pools = new uint256[](1);
        // Convert pool0 to uint256 type and set WETH_UNWRAP_MASK flag
        pools[0] = uint256(pool0) | _WETH_UNWRAP_MASK;

        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), type(uint256).max);
            dexRouterExactOut.uniswapV3SwapExactOutTo(
                uint256(uint160(amy)),
                amountOut,
                amountInMax,
                pools); 
        vm.stopPrank();

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[targetTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", amy.balance);
    }
} 
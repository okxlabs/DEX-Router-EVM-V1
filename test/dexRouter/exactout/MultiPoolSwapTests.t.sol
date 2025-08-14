// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/BaseTestSetup.t.sol";

contract MultiPoolSwapTests is BaseTestSetup {
    // V2 Test
    // Testing multi pool exchange
    function testERC20TokenMultiPoolExchange() public {
        uint256 sourceTokenIndex = 1;
        uint256 middleTokenIndex = 2;
        uint256 targetTokenIndex = 3;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        IUniswapV2Pair pair12 = IUniswapV2Pair(pairMatrix[1][2]);
        IUniswapV2Pair pair23 = IUniswapV2Pair(pairMatrix[2][3]);
        console2.log("pair12:", address(pair12));
        console2.log("pair23:", address(pair23));
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pair12), false);
        bytes32 pool1 = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pair23), false);
        bytes32[] memory pools = new bytes32[](2);
        pools[0] = pool0;
        pools[1] = pool1;
        console2.logBytes32(pool0);
        console2.logBytes32(pool1);

        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), amountInMax);
            console2.log("Approved tokenApprove:", address(tokenApprove));
            console2.log("Approval amount:", tokens[sourceTokenIndex].allowance(amy, address(tokenApprove)));
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            dexRouterExactOut.unxswapExactOutTo(
                uint256(uint160(address(tokens[sourceTokenIndex]))),
                amountOut,
                amountInMax,
                amy,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
    }

    // Testing multi pool exchange (ETH as sourceToken)
    function testETHSourceMultiPoolExchange() public {
        uint256 sourceTokenIndex = 0; // ETH/WETH
        uint256 middleTokenIndex = 1;
        uint256 targetTokenIndex = 2;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        IUniswapV2Pair pair01 = IUniswapV2Pair(pairMatrix[0][1]);
        IUniswapV2Pair pair12 = IUniswapV2Pair(pairMatrix[1][2]);
        console2.log("pair01:", address(pair01));
        console2.log("pair12:", address(pair12));
        console2.log("sourceToken:", address(ETH));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        console2.log("before sourceToken balance:", amy.balance);
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pair01), false);
        bytes32 pool1 = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pair12), false);
        bytes32[] memory pools = new bytes32[](2);
        pools[0] = pool0;
        pools[1] = pool1;
        console2.logBytes32(pool0);
        console2.logBytes32(pool1);

        vm.startPrank(amy);
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            dexRouterExactOut.unxswapExactOutTo{value: amountInMax}(
                uint256(uint160(ETH)),
                amountOut,
                amountInMax,
                amy,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", amy.balance);
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
    }

    // Testing multi pool exchange (ETH as targetToken)
    function testETHTargetMultiPoolExchange() public {
        uint256 sourceTokenIndex = 1;
        uint256 middleTokenIndex = 2;
        uint256 targetTokenIndex = 0; // ETH/WETH
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        IUniswapV2Pair pair12 = IUniswapV2Pair(pairMatrix[1][2]);
        IUniswapV2Pair pair20 = IUniswapV2Pair(pairMatrix[2][0]);
        console2.log("pair12:", address(pair12));
        console2.log("pair20:", address(pair20));
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(ETH));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", amy.balance);

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pair12), false);
        bytes32 pool1 = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pair20), true);
        bytes32[] memory pools = new bytes32[](2);
        pools[0] = pool0;
        pools[1] = pool1;
        console2.logBytes32(pool0);
        console2.logBytes32(pool1);

        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), amountInMax);
            console2.log("Approved tokenApprove:", address(tokenApprove));
            console2.log("Approval amount:", tokens[sourceTokenIndex].allowance(amy, address(tokenApprove)));
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            dexRouterExactOut.unxswapExactOutTo(
                uint256(uint160(address(tokens[sourceTokenIndex]))),
                amountOut,
                amountInMax,
                amy,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", amy.balance);
    }

    // V3 Test
    // Testing multi pool exchange V3
    function testERC20TokenMultiPoolExchangeV3() public {
        uint256 sourceTokenIndex = 1;
        uint256 middleTokenIndex = 2;
        uint256 targetTokenIndex = 3;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        IUniswapV3Pool pair12 = IUniswapV3Pool(v3PairMatrix[1][2]);
        IUniswapV3Pool pair23 = IUniswapV3Pool(v3PairMatrix[2][3]);
        console2.log("pair12:", address(pair12));
        console2.log("pair23:", address(pair23));
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pair12), false);
        bytes32 pool1 = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pair23), false);
        
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(pool0);
        pools[1] = uint256(pool1);
        
        console2.log("Pool0 data:", uint256(pool0));
        console2.log("Pool1 data:", uint256(pool1));

        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), amountInMax);
            console2.log("Approved tokenApprove:", address(tokenApprove));
            console2.log("Approval amount:", tokens[sourceTokenIndex].allowance(amy, address(tokenApprove)));
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            dexRouterExactOut.uniswapV3SwapExactOutTo(
                uint256(uint160(amy)),
                amountOut,
                amountInMax,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
    }
    
    // Testing multi pool exchange V3 (ETH as sourceToken)
    function testETHTargetMultiPoolExchangeV3() public {
        uint256 sourceTokenIndex = 1;
        uint256 middleTokenIndex = 2;
        uint256 targetTokenIndex = 0; // ETH/WETH
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        IUniswapV3Pool pair12 = IUniswapV3Pool(v3PairMatrix[1][2]);
        IUniswapV3Pool pair20 = IUniswapV3Pool(v3PairMatrix[2][0]);
        console2.log("pair12:", address(pair12));
        console2.log("pair20:", address(pair20));
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(ETH));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", amy.balance);

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pair12), false);
        bytes32 pool1 = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pair20), true);
        
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(pool0);
        // Convert pool1 into uint256, and set mask: WETH_UNWRAP_MASK
        pools[1] = uint256(pool1) | _WETH_UNWRAP_MASK;
        
        console2.log("Pool0 data:", uint256(pool0));
        console2.log("Pool1 data with unwrap flag:", pools[1]);

        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), amountInMax);
            console2.log("Approved tokenApprove:", address(tokenApprove));
            console2.log("Approval amount:", tokens[sourceTokenIndex].allowance(amy, address(tokenApprove)));
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            dexRouterExactOut.uniswapV3SwapExactOutTo(
                uint256(uint160(amy)),
                amountOut,
                amountInMax,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", amy.balance);
    }

    // Testing multi pool exchange V3 (ETH as targetToken)
    function testETHSourceMultiPoolExchangeV3() public {
        uint256 sourceTokenIndex = 0; // ETH/WETH
        uint256 middleTokenIndex = 1;
        uint256 targetTokenIndex = 2;
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        IUniswapV3Pool pair01 = IUniswapV3Pool(v3PairMatrix[0][1]);
        IUniswapV3Pool pair12 = IUniswapV3Pool(v3PairMatrix[1][2]);
        console2.log("pair01:", address(pair01));
        console2.log("pair12:", address(pair12));
        console2.log("sourceToken:", address(ETH));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(tokens[targetTokenIndex]));
        console2.log("before sourceToken balance:", amy.balance);
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));

        bytes32 pool0 = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pair01), false);
        bytes32 pool1 = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pair12), false);
        
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(pool0);
        pools[1] = uint256(pool1);
        
        console2.log("Pool0 data:", uint256(pool0));
        console2.log("Pool1 data:", uint256(pool1));

        vm.startPrank(amy);
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            dexRouterExactOut.uniswapV3SwapExactOutTo{value: amountInMax}(
                uint256(uint160(amy)),
                amountOut,
                amountInMax,
                pools
            );
        vm.stopPrank();

        console2.log("after sourceToken balance:", amy.balance);
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", tokens[targetTokenIndex].balanceOf(amy));
    }
} 

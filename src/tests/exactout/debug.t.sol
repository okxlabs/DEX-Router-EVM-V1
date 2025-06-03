// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/BaseTestSetup.t.sol";

contract debug is BaseTestSetup {

    function testCommissionToTokenMultiPoolWithETHTarget() public {
        uint256 sourceTokenIndex = 1;
        uint256 middleTokenIndex = 2;
        uint256 targetTokenIndex = 0; // ETH/WETH
        uint256 amountOut = 400e18;
        uint256 amountInMax = 600e18;

        // 直接使用pairMatrix，不创建局部变量
        console2.log("pair12:", address(pairMatrix[1][2]));
        console2.log("pair20:", address(pairMatrix[2][0]));
        console2.log("sourceToken:", address(tokens[sourceTokenIndex]));
        console2.log("middleToken:", address(tokens[middleTokenIndex]));
        console2.log("targetToken:", address(ETH));
        console2.log("before sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("before middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("before targetToken balance:", amy.balance);
        console2.log("before referer balance:", refererAddress.balance);

        // 创建pools数组并直接填充
        bytes32[] memory pools = new bytes32[](2);
        pools[0] = _buildPool(address(tokens[sourceTokenIndex]), address(tokens[middleTokenIndex]), address(pairMatrix[1][2]), false);
        pools[1] = _buildPool(address(tokens[middleTokenIndex]), address(tokens[targetTokenIndex]), address(pairMatrix[2][0]), true);

        // 内联构建调用数据
        vm.startPrank(amy);
            tokens[sourceTokenIndex].approve(address(tokenApprove), UINT256_MAX);
            console2.log("Approved tokenApprove:", address(tokenApprove));
            console2.log("Approval amount:", tokens[sourceTokenIndex].allowance(amy, address(tokenApprove)));
            console2.log("Amy address:", amy);
            console2.log("DexRouter address:", address(dexRouterExactOut));
            
            bytes memory generated_commission = _buildCommissionInfoUnified(
                false, // 不从源代币收取
                true,  // 从目标代币收取
                COMMISSION_ETH,
                10000000,   // 0.1%的佣金率
                refererAddress,
                0,
                address(0)
            );
            
            console2.log("Generated commission info:");
            console2.logBytes(generated_commission);

            // 直接构建并连接数据
            (bool success, ) = address(dexRouterExactOut).call(
                bytes.concat(
                    abi.encodeWithSelector(
                        dexRouterExactOut.unxswapExactOutTo.selector,
                        uint256(uint160(address(tokens[sourceTokenIndex]))),
                        amountOut,
                        amountInMax,
                        amy,
                        pools
                    ),
                    generated_commission
                )
            );
            require(success, "call failed");
        vm.stopPrank(); 

        console2.log("after sourceToken balance:", tokens[sourceTokenIndex].balanceOf(amy));
        console2.log("after middleToken balance:", tokens[middleTokenIndex].balanceOf(amy));
        console2.log("after targetToken balance:", amy.balance);
        console2.log("after referer balance:", refererAddress.balance);
    }

} 
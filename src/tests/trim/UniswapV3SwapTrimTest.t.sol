// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrimTestBase.t.sol";

/*
 * The uniswapV3Swap method is tested with condition1 * condition2:
 * condition1:
 *     (1) ERC20 -> ERC20
 *     (2) ETH -> ERC20
 *     (3) ERC20 -> ETH
 * condition2:
 *     (1) noTrim + noCommission
 *     (2) 1trim + noCommission
 *     (3) 2trim + noCommission
 *     (4) 1trim + 1toCommission
 *     (5) 2trim + 1toCommission
 *     (6) 1trim + 2toCommission
 *     (7) 2trim + 2toCommission
 *     (8) 2trim + 2fromCommission
*/
contract UniswapV3SwapTrimTest is TrimTestBase {

    // ==================== ERC20->ERC20 ====================
    // ERC20->ERC20 with noTrim and noCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_noTrim_noCommission() tokenLogAndCheck(WETH, USDT, oneEther, false, false, false, false, false)  public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        (bool success, ) = address(dexRouter).call(swapData);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 1trim and noCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_1trim_noCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, false, false, false, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 2trim and noCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_2trim_noCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, true, false, false, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 1trim and 1toCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_1trim_1toCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, false, false, true, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory commissionData = _generate1CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 2trim and 1toCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_2trim_1toCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, true, false, true, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate1CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 1trim and 2toCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_1trim_2toCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, false, false, true, true) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory commissionData = _generate2CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 2trim and 2toCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_2trim_2toCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, true, false, true, true) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate2CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }
    
    // ERC20->ERC20 with 2trim and 2fromCommission
    function test_trim_uniswapV3SwapTo_WETH2USDT_2trim_2fromCommission() tokenLogAndCheck(WETH, USDT, 2 * 10 ** 18, true, true, true, true, true) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate2CommissionData(true, WETH);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ==================== ETH->ERC20 ====================
    // ETH->ERC20 with noTrim and noCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_noTrim_noCommission() tokenLogAndCheck(ETH, USDT, oneEther, false, false, false, false, false)  public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        (bool success, ) = address(dexRouter).call{value: oneEther}(swapData);
        require(success, "call failed");
    }

    // ETH->ERC20 with 1trim and noCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_1trim_noCommission() tokenLogAndCheck(ETH, USDT, oneEther, true, false, false, false, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        require(success, "call failed");
    }

    // ETH->ERC20 with 2trim and noCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_2trim_noCommission() tokenLogAndCheck(ETH, USDT, oneEther, true, true, false, false, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        require(success, "call failed");
    }

    // ETH->ERC20 with 1trim and 1toCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_1trim_1toCommission() tokenLogAndCheck(ETH, USDT, oneEther, true, false, false, true, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory commissionData = _generate1CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        require(success, "call failed");
    }

    // ETH->ERC20 with 2trim and 1toCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_2trim_1toCommission() tokenLogAndCheck(ETH, USDT, oneEther, true, true, false, true, false) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate1CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        require(success, "call failed");
    }

    // ETH->ERC20 with 1trim and 2toCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_1trim_2toCommission() tokenLogAndCheck(ETH, USDT, oneEther, true, false, false, true, true) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory commissionData = _generate2CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        require(success, "call failed");
    }

    // ETH->ERC20 with 2trim and 2toCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_2trim_2toCommission() tokenLogAndCheck(ETH, USDT, oneEther, true, true, false, true, true) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate2CommissionData(false, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        require(success, "call failed");
    }
    
    // ETH->ERC20 with 2trim and 2fromCommission
    function test_trim_uniswapV3SwapTo_ETH2USDT_2trim_2fromCommission() tokenLogAndCheck(ETH, USDT, 2 * 10 ** 18, true, true, true, true, true) public {
        bytes memory swapData = _generateWETH2USDTUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate2CommissionData(true, ETH);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call{value: 2 * 10 ** 18}(data);
        require(success, "call failed");
    }

    // ==================== ERC20->ETH ====================
    // ERC20->ETH with noTrim and noCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_noTrim_noCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, false, false, false, false, false)  public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        (bool success, ) = address(dexRouter).call(swapData);
        require(success, "call failed");
    }

    // ERC20->ETH with 1trim and noCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_1trim_noCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, true, false, false, false, false) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ETH with 2trim and noCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_2trim_noCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, true, true, false, false, false) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ETH with 1trim and 1toCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_1trim_1toCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, true, false, false, true, false) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory commissionData = _generate1CommissionData(false, ETH);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ETH with 2trim and 1toCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_2trim_1toCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, true, true, false, true, false) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate1CommissionData(false, ETH);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ETH with 1trim and 2toCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_1trim_2toCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, true, false, false, true, true) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate1TrimData();
        bytes memory commissionData = _generate2CommissionData(false, ETH);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ERC20->ETH with 2trim and 2toCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_2trim_2toCommission() tokenLogAndCheck(USDT, ETH, 1000 * 10 ** 6, true, true, false, true, true) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate2CommissionData(false, ETH);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }
    
    // ERC20->ETH with 2trim and 2fromCommission
    function test_trim_uniswapV3SwapTo_USDT2ETH_2trim_2fromCommission() tokenLogAndCheck(USDT, ETH, 2000 * 10 ** 6, true, true, true, true, true) public {
        bytes memory swapData = _generateUSDT2ETHUniswapV3SwapData();
        bytes memory trimData = _generate2TrimData();
        bytes memory commissionData = _generate2CommissionData(true, USDT);
        bytes memory data = bytes.concat(swapData, trimData, commissionData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // ==================== Internal Functions ====================
    function _generateWETH2USDTUniswapV3SwapData() internal view returns (bytes memory) {
        uint256 receiver = uint256(uint160(arnaud));
        uint256 amount = oneEther;
        uint256 minReturn = 0;
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(amount), address(WETH_USDT_UNIV3))));
        return abi.encodeWithSelector(
            DexRouter.uniswapV3SwapTo.selector, receiver, amount, minReturn, pools
        );
    }

    function _generateUSDT2ETHUniswapV3SwapData() internal view returns (bytes memory) {
        uint256 receiver = uint256(uint160(arnaud));
        uint256 amount = 1000 * 10 ** 6;
        uint256 minReturn = 0;
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(bytes32(abi.encodePacked(uint8(0xa0), uint56(0), uint32(amount), address(WETH_USDT_UNIV3))));
        return abi.encodeWithSelector(
            DexRouter.uniswapV3SwapTo.selector, receiver, amount, minReturn, pools
        );
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrimTestBase.t.sol";

/*
 * The smartSwap method is tested with condition1 * condition2:
 * condition1:
 *     (1) ERC20 -> ERC20
 *     (2) ETH -> ERC20
 *     (3) ERC20 -> ETH
 * condition2:
 *     (1) noTrim + noToCommission
 *     (2) 1trim + noToCommission
 *     (3) 2trim + noToCommission
 *     (4) 1trim + 1toCommission
 *     (5) 2trim + 1toCommission
 *     (6) 1trim + 2toCommission
 *     (7) 2trim + 2toCommission
*/
contract SmartSwapTrimTest is TrimTestBase {
    
    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    // ERC20->ERC20 with noTrim and noToCommission
    function test_trim_smartSwapTo_WETH2USDT_noTrim_noToCommission() tokenLogAndCheck(WETH, USDT, oneEther, false, false, false, false)  public {
        bytes memory swapData = _generateWETH2USDTSmartSwapData();
        (bool success, ) = address(dexRouter).call(swapData);
        require(success, "call failed");
    }

    // ERC20->ERC20 with 1trim and noToCommission
    function test_trim_smartSwapTo_WETH2USDT_1trim_noToCommission() tokenLogAndCheck(WETH, USDT, oneEther, true, false, false, false) public {
        bytes memory swapData = _generateWETH2USDTSmartSwapData();
        bytes memory trimData = _generate1TrimData();
        console2.logBytes(trimData);
        TrimHelper.TrimInfo memory trimInfo = TrimHelper._parseTrimInfo(trimData);
        bytes memory data = bytes.concat(swapData, trimData);
        (bool success, ) = address(dexRouter).call(data);
        require(success, "call failed");
    }

    // // ERC20->ERC20 with 2trim and noToCommission
    // function test_trim_smartSwapTo_WETH2USDT_2trim_noToCommission() public {

    // }

    // // ERC20->ERC20 with 1trim and 1toCommission
    // function test_trim_smartSwapTo_WETH2USDT_1trim_1toCommission() public {

    // }

    // // ERC20->ERC20 with 2trim and 1toCommission
    // function test_trim_smartSwapTo_WETH2USDT_2trim_1toCommission() public {

    // }

    // // ERC20->ERC20 with 1trim and 2toCommission
    // function test_trim_smartSwapTo_WETH2USDT_1trim_2toCommission() public {

    // }

    // // ERC20->ERC20 with 2trim and 2toCommission
    // function test_trim_smartSwapTo_WETH2USDT_2trim_2toCommission() public {

    // }

    // ==================== Internal Functions ====================
    function _generateWETH2USDTSmartSwapData() internal view returns (bytes memory) {
        SwapInfo memory swapInfo;
        // baseRequest
        swapInfo.baseRequest = _generateBaseRequest(WETH, USDT, oneEther);
        // batchesAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = oneEther;
        // batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(UniversalUniV3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(UniversalUniV3Adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WETH_USDT_UNIV3))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(WETH, USDT, 0));
        swapInfo.batches[0][0].fromToken = uint256(uint160(WETH));
        // extraData
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        return abi.encodeWithSelector(
            DexRouter.smartSwapTo.selector,
            swapInfo.orderId, arnaud, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }
}
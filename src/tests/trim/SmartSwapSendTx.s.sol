// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/DexRouter.sol";
import "../common/CommissionHelper.t.sol";
import "../common/TrimHelper.t.sol";

// cmd: forge script src/tests/trim/SmartSwapSendTx.s.sol:SendTx -vvv (--broadcast)

contract SendTx is Test, CommissionHelper, TrimHelper {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    uint256 amountIn = 0.00001 * 10 ** 18 + 0.00001 * 10 ** 16 * 3; // inputAmount + fromTokenCommission
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address UniversalUniV3Adapter = 0x7A7AD9aa93cd0A2D0255326E5Fb145CEc14997FF;
    address WETH_USDC_UNIV3 = 0x6bcb0Ba386E9de0C29006e46B2f01f047cA1806E;
    address dexRouter = 0xF4858d71e5d7D27e3F7270390Cd57545DcA35aa9;
    address ownedAddress = 0x87689BCAe752592965F1dceC6d5b74E968Ea78b5;

    function _generateETH2USDCSmartSwapData() internal view returns (bytes memory) {
        SwapInfo memory swapInfo;
        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(ETH));
        swapInfo.baseRequest.toToken = USDC;
        swapInfo.baseRequest.fromTokenAmount = amountIn;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp + 1000;
        // batchesAmount
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amountIn;
        // batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(UniversalUniV3Adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(UniversalUniV3Adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WETH_USDC_UNIV3))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(WETH, USDC, 0));
        swapInfo.batches[0][0].fromToken = uint256(uint160(WETH));
        // extraData
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        return abi.encodeWithSelector(
            DexRouter.smartSwapTo.selector,
            swapInfo.orderId, deployer, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

    function run() public {
        console2.log("deployer", deployer);

        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        console2.log("amountIn", amountIn);

        console2.log("deployer balance before", address(deployer).balance);
        console2.log("ownedAddress balance before", address(ownedAddress).balance);
        console2.log("deployer USDC balance before", IERC20(USDC).balanceOf(address(deployer)));
        console2.log("ownedAddress USDC balance before", IERC20(USDC).balanceOf(address(ownedAddress)));

        bytes memory swapData = _generateETH2USDCSmartSwapData();
        bytes memory commissionData = _buildCommissionInfoUnified(
            true,
            false,
            ETH,
            10000000,
            ownedAddress,
            20000000,
            deployer,
            true
        );
        bytes memory trimData = _buildTrimInfoUnified(
            100,
            ownedAddress,
            2000,
            300,
            deployer
        );
        bytes memory data = bytes.concat(swapData, commissionData, trimData);
        (bool success, ) = address(dexRouter).call{value: amountIn}(data);
        require(success, "call failed");

        console2.log("deployer balance after", address(deployer).balance);
        console2.log("ownedAddress balance after", address(ownedAddress).balance);
        console2.log("deployer USDC balance after", IERC20(USDC).balanceOf(address(deployer)));
        console2.log("ownedAddress USDC balance after", IERC20(USDC).balanceOf(address(ownedAddress)));

        vm.stopBroadcast();
    }
}

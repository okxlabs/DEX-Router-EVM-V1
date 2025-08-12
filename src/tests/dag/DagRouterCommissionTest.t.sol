pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./DagRouterTestBase.t.sol";
import "../common/CommissionHelper.t.sol";

/*
 * Commission cases is tested with case2 in DagRouterTestBase.
 *  10% A → D
 *  40% A → C
 *  50% A → B → C
 *          ↳ 100% C → D  
*/
contract DagRouterCommissionTest is DagRouterTestBase, CommissionHelper {
    address public referrer1 = vm.rememberKey(2222222222);
    address public referrer2 = vm.rememberKey(333333333);

    function test_DagRouter_fromTokenCommission() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        address fromToken = tokens[0]; // WETH
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            true,
            false,
            fromToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            0,
            address(0),
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 fromToken balance before:", IERC20(fromToken).balanceOf(referrer1));
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 fromToken balance after:", IERC20(fromToken).balanceOf(referrer1));
        require(success, "call failed");
    }

    function test_DagRouter_fromTokenCommissionDual() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        address fromToken = tokens[0]; // WETH
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            true,
            false,
            fromToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            1000000,
            referrer2,
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 fromToken balance before:", IERC20(fromToken).balanceOf(referrer1));
        console2.log("referrer2 fromToken balance before:", IERC20(fromToken).balanceOf(referrer2));
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 fromToken balance after:", IERC20(fromToken).balanceOf(referrer1));
        console2.log("referrer2 fromToken balance after:", IERC20(fromToken).balanceOf(referrer2));
        require(success, "call failed");
    }

    function test_DagRouter_fromTokenCommissionDualToB() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        address fromToken = tokens[0]; // WETH
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            true,
            false,
            fromToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            1000000,
            referrer2,
            true
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 fromToken balance before:", IERC20(fromToken).balanceOf(referrer1));
        console2.log("referrer2 fromToken balance before:", IERC20(fromToken).balanceOf(referrer2));
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 fromToken balance after:", IERC20(fromToken).balanceOf(referrer1));
        console2.log("referrer2 fromToken balance after:", IERC20(fromToken).balanceOf(referrer2));
        require(success, "call failed");
    }

    function test_DagRouter_fromETHCommission() public userWithToken(arnaud, ETH, tokens[3], oneEther) noResidue {
        address fromToken = ETH;
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            true,
            false,
            fromToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            0,
            address(0),
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 ETH balance before:", referrer1.balance);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        console2.log("referrer1 ETH balance after:", referrer1.balance);
        require(success, "call failed");
    }

    function test_DagRouter_fromETHCommissionDual() public userWithToken(arnaud, ETH, tokens[3], oneEther) noResidue {
        address fromToken = ETH;
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            true,
            false,
            fromToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            1000000,
            referrer2,
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 ETH balance before:", referrer1.balance);
        console2.log("referrer2 ETH balance before:", referrer2.balance);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        console2.log("referrer1 ETH balance after:", referrer1.balance);
        console2.log("referrer2 ETH balance after:", referrer2.balance);
        require(success, "call failed");
    }

    function test_DagRouter_fromETHCommissionDualToB() public userWithToken(arnaud, ETH, tokens[3], oneEther) noResidue {
        address fromToken = ETH;
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            true,
            false,
            fromToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            1000000,
            referrer2,
            true
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 ETH balance before:", referrer1.balance);
        console2.log("referrer2 ETH balance before:", referrer2.balance);
        (bool success, ) = address(dexRouter).call{value: oneEther}(data);
        console2.log("referrer1 ETH balance after:", referrer1.balance);
        console2.log("referrer2 ETH balance after:", referrer2.balance);
        require(success, "call failed");
    }

    function test_DagRouter_toTokenCommission() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        address fromToken = tokens[0]; // WETH
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            false,
            true,
            toToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            0,
            address(0),
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 toToken balance before:", IERC20(toToken).balanceOf(referrer1));
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 toToken balance after:", IERC20(toToken).balanceOf(referrer1));
        require(success, "call failed");
    }

    function test_DagRouter_toTokenCommissionDual() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        address fromToken = tokens[0]; // WETH
        address toToken = tokens[3]; // USDC
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            false,
            true,
            toToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            1000000,
            referrer2,
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 toToken balance before:", IERC20(toToken).balanceOf(referrer1));
        console2.log("referrer2 toToken balance before:", IERC20(toToken).balanceOf(referrer2));
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 toToken balance after:", IERC20(toToken).balanceOf(referrer1));
        console2.log("referrer2 toToken balance after:", IERC20(toToken).balanceOf(referrer2));
        require(success, "call failed");
    }

    function test_DagRouter_toETHCommission() public userWithToken(arnaud, tokens[3], ETH, 1000 * 10 ** 6) noResidue {
        address fromToken = tokens[3]; // USDC
        address toToken = ETH;
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, 1000 * 10 ** 6);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_USDC2WETH();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            false,
            true,
            toToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            0,
            address(0),
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 ETH balance before:", referrer1.balance);
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 ETH balance after:", referrer1.balance);
        require(success, "call failed");
    }

    function test_DagRouter_toETHCommissionDual() public userWithToken(arnaud, tokens[3], ETH, 1000 * 10 ** 6) noResidue {
        address fromToken = tokens[3]; // USDC
        address toToken = ETH;
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(fromToken, toToken, 1000 * 10 ** 6);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_USDC2WETH();
        bytes memory commissionInfo = _buildCommissionInfoUnified(
            false,
            true,
            toToken,
            1000000, // denominator = 10 ** 9, 10*6 = 0.1%
            referrer1,
            1000000,
            referrer2,
            false
        );
        bytes memory preData = abi.encodeWithSelector(
            DexRouter.dagSwapTo.selector,
            0,
            arnaud,
            baseRequest,
            paths
        );
        bytes memory data = bytes.concat(preData, commissionInfo);
        console2.log("referrer1 ETH balance before:", referrer1.balance);
        console2.log("referrer2 ETH balance before:", referrer2.balance);
        (bool success, ) = address(dexRouter).call(data);
        console2.log("referrer1 ETH balance after:", referrer1.balance);
        console2.log("referrer2 ETH balance after:", referrer2.balance);
        require(success, "call failed");
    }
}
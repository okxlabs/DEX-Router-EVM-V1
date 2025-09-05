// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@dex/DexRouter.sol";
import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/libraries/SafeERC20.sol";
import "../common/CommissionHelper.t.sol";
import "../common/TrimHelper.t.sol";

contract TrimTestBase is Test, CommissionHelper, TrimHelper {
    // tokens
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // decimals=18
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // decimals=6
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // decimals=6

    // pools
    address constant WETH_USDT_UNIV2 = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
    address constant WETH_USDT_UNIV3 = 0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36;
    address constant USDC_WETH_UNIV2 = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address constant USDC_WETH_UNIV3 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;

    // users
    address public admin = vm.rememberKey(1);
    address public arnaud = vm.rememberKey(11111111111111111111);
    address public trimAddress = vm.rememberKey(22222222222222222222);
    address public trimAddress2 = vm.rememberKey(33333333333333333333);
    address public referrerAddress = vm.rememberKey(44444444444444444444);
    address public referrerAddress2 = vm.rememberKey(55555555555555555555);
    
    // contracts
    DexRouter public dexRouter;
    TokenApprove tokenApprove = TokenApprove(0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f); // ETH
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58); // ETH
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0x5703B683c7F928b721CA95Da988d73a3299d4757)); // ETH

    address constant UniversalUniV3Adapter = 0x6747BcaF9bD5a5F0758Cbe08903490E45DdfACB5;
    address constant UniV2Adapter = 0xc837BbEa8C7b0caC0e8928f797ceB04A34c9c06e;

    uint256 public oneEther = 1 * 10 ** 18;

    modifier tokenLogAndCheck(address _fromToken, address _toToken, uint256 _amount, bool trim1ShouldReceive, bool trim2ShouldReceive, bool referrer1ShouldReceive, bool referrer2ShouldReceive) {
        vm.startPrank(arnaud);
        console2.log("User arnaud:", arnaud);
        address[] memory tokens = new address[](2);
        tokens[0] = _fromToken;
        tokens[1] = _toToken;
        console2.log("========== before swap ==========");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == ETH) {
                deal(address(arnaud), _amount);
                console2.log(
                    "arnaud ETH balance before: %d",
                    address(arnaud).balance
                );
                uint256 trim1Balance = address(trimAddress).balance;
                console2.log("trim1 ETH balance before: %d", trim1Balance);
                require(trim1Balance == 0, "trim1 ETH balance before should be 0");
                uint256 trim2Balance = address(trimAddress2).balance;
                console2.log("trim2 ETH balance before: %d", trim2Balance);
                require(trim2Balance == 0, "trim2 ETH balance before should be 0");
                uint256 referrer1Balance = address(referrerAddress).balance;
                console2.log("referrer1 ETH balance before: %d", referrer1Balance);
                require(referrer1Balance == 0, "referrer1 ETH balance before should be 0");
                uint256 referrer2Balance = address(referrerAddress2).balance;
                console2.log("referrer2 ETH balance before: %d", referrer2Balance);
                require(referrer2Balance == 0, "referrer2 ETH balance before should be 0");
            } else {
                deal(token, arnaud, _amount);
                SafeERC20.safeApprove(IERC20(token), address(tokenApprove), _amount);
                console2.log(
                    "%s balance before: %d",
                    IERC20(token).symbol(),
                    IERC20(token).balanceOf(address(arnaud))
                );
                uint256 trim1Balance = IERC20(token).balanceOf(address(trimAddress));
                console2.log("trim1 %s balance before: %d", IERC20(token).symbol(), trim1Balance);
                require(trim1Balance == 0, "trim1 balance before should be 0");
                uint256 trim2Balance = IERC20(token).balanceOf(address(trimAddress2));
                console2.log("trim2 %s balance before: %d", IERC20(token).symbol(), trim2Balance);
                require(trim2Balance == 0, "trim2 balance before should be 0");
                uint256 referrer1Balance = IERC20(token).balanceOf(address(referrerAddress));
                console2.log("referrer1 %s balance before: %d", IERC20(token).symbol(), referrer1Balance);
                require(referrer1Balance == 0, "referrer1 balance before should be 0");
                uint256 referrer2Balance = IERC20(token).balanceOf(address(referrerAddress2));
                console2.log("referrer2 %s balance before: %d", IERC20(token).symbol(), referrer2Balance);
                require(referrer2Balance == 0, "referrer2 balance before should be 0");
            }
        }
        _;
        console2.log("========== after swap ==========");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == ETH) {
                console2.log("arnaud ETH balance after: %d", address(arnaud).balance);
                uint256 trim1Balance = address(trimAddress).balance;
                console2.log("trim1 ETH balance after: %d", trim1Balance);
                require(
                    (trim1ShouldReceive && trim1Balance > 0) || (!trim1ShouldReceive && trim1Balance == 0),
                    "trim1 ETH balance after should be > 0"
                );
                uint256 trim2Balance = address(trimAddress2).balance;
                console2.log("trim2 ETH balance after: %d", trim2Balance);
                require(
                    (trim2ShouldReceive && trim2Balance > 0) || (!trim2ShouldReceive && trim2Balance == 0),
                    "trim2 ETH balance after should be > 0"
                );
                uint256 referrer1Balance = address(referrerAddress).balance;
                console2.log("referrer1 ETH balance after: %d", referrer1Balance);
                require(
                    (referrer1ShouldReceive && referrer1Balance > 0) || (!referrer1ShouldReceive && referrer1Balance == 0),
                    "referrer1 ETH balance after should be > 0"
                );
                uint256 referrer2Balance = address(referrerAddress2).balance;
                console2.log("referrer2 ETH balance after: %d", referrer2Balance);
                require(
                    (referrer2ShouldReceive && referrer2Balance > 0) || (!referrer2ShouldReceive && referrer2Balance == 0),
                    "referrer2 ETH balance after should be > 0"
                );
            } else {
                console2.log("%s balance after: %d", IERC20(token).symbol(), IERC20(token).balanceOf(address(arnaud)));
                uint256 trim1Balance = IERC20(token).balanceOf(address(trimAddress));
                console2.log("trim1 %s balance after: %d", IERC20(token).symbol(), trim1Balance);
                require(
                    (trim1ShouldReceive && trim1Balance > 0) || (!trim1ShouldReceive && trim1Balance == 0),
                    "trim1 balance after should be > 0"
                );
                uint256 trim2Balance = IERC20(token).balanceOf(address(trimAddress2));
                console2.log("trim2 %s balance after: %d", IERC20(token).symbol(), trim2Balance);
                require(
                    (trim2ShouldReceive && trim2Balance > 0) || (!trim2ShouldReceive && trim2Balance == 0),
                    "trim2 balance after should be > 0"
                );
                uint256 referrer1Balance = IERC20(token).balanceOf(address(referrerAddress));
                console2.log("referrer1 %s balance after: %d", IERC20(token).symbol(), referrer1Balance);
                require(
                    (referrer1ShouldReceive && referrer1Balance > 0) || (!referrer1ShouldReceive && referrer1Balance == 0),
                    "referrer1 balance after should be > 0"
                );
                uint256 referrer2Balance = IERC20(token).balanceOf(address(referrerAddress2));
                console2.log("referrer2 %s balance after: %d", IERC20(token).symbol(), referrer2Balance);
                require(
                    (referrer2ShouldReceive && referrer2Balance > 0) || (!referrer2ShouldReceive && referrer2Balance == 0),
                    "referrer2 balance after should be > 0"
                );
            }
        }
        vm.stopPrank();
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 23293873); // 2025.9.5 10:18
        vm.startPrank(admin);
        dexRouter = new DexRouter();
        vm.stopPrank();
        address wNativeRelayerOwner = wNativeRelayer.owner();
        vm.startPrank(wNativeRelayerOwner);
        tokenApproveProxy.addProxy(address(dexRouter));
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
    }

    // ==================== Internal Functions ====================
    function _generateBaseRequest(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) internal view returns (DexRouter.BaseRequest memory baseRequest) {
        baseRequest.fromToken = uint256(uint160(_fromToken));
        baseRequest.toToken = _toToken;
        baseRequest.fromTokenAmount = _amount;
        baseRequest.minReturnAmount = 0;
        baseRequest.deadLine = block.timestamp + 1000;
    }

    function _generate1TrimData() internal view returns (bytes memory) {
        return _buildTrimInfoUnified(
            50, // trimRate 5%
            trimAddress, // trimAddress
            100, // expectAmountOut 100, but usually the trimAmount will be the allowedMaxTrimAmount cause the expectAmountOut is too small
            0, // trimRate2 0%
            address(0) // trimAddress2
        );
    }

    function _generate2TrimData() internal view returns (bytes memory) {
        return _buildTrimInfoUnified(
            50, // trimRate 5%
            trimAddress, // trimAddress
            100, // expectAmountOut 100, but usually the trimAmount will be the allowedMaxTrimAmount cause the expectAmountOut is too small
            50, // trimRate2 5%
            trimAddress2 // trimAddress2
        );
    }

    function _generate1ToCommissionData(address token) internal view returns (bytes memory) {
        return _buildCommissionInfoUnified(
            false, // isFromTokenCommission
            true, // isToTokenCommission
            token, // token
            1000000, // commissionRate 0.1%, denominator = 10 ** 9
            referrerAddress, // refererAddress
            0, // commissionRate2 0%
            address(0), // refererAddress2
            false // isToBCommission
        );
    }

    function _generate2ToCommissionData(address token) internal view returns (bytes memory) {
        return _buildCommissionInfoUnified(
            false, // isFromTokenCommission
            true, // isToTokenCommission
            token, // token
            1000000, // commissionRate 0.1%, denominator = 10 ** 9
            referrerAddress, // refererAddress
            10000000, // commissionRate2 0.1%, denominator = 10 ** 9
            referrerAddress2, // refererAddress2
            false // isToBCommission
        );
    }
}
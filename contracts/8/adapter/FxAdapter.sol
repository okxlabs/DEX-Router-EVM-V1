// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IFxProtocol.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

// only for ETH
contract FxAdapter is IAdapter {

    address constant FX_MARKET = 0xe7b9c7c9cA85340b8c06fb805f7775e3015108dB;
    address constant FETH_ADDRESS = 0x53805A76E1f5ebbFE7115F16f9c87C2f7e633726; 
    address constant XETH_ADDRESS = 0xe063F04f280c60aECa68b38341C2eEcBeC703ae2;
    address constant STETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function _mintxeth(
        address to
    ) internal {
        uint256 sellAmount = IERC20(STETH_ADDRESS).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(STETH_ADDRESS),
            FX_MARKET,
            sellAmount
        );
        IFxMarket(FX_MARKET).mintFToken(sellAmount, to, 0);
    }
    function _mintfeth(
        address to
    ) internal {
        uint256 sellAmount = IERC20(STETH_ADDRESS).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(STETH_ADDRESS),
            FX_MARKET,
            sellAmount
        );
        IFxMarket(FX_MARKET).mintXToken(sellAmount, to, 0);
    }

    function _redeemxeth(
        address to
    ) internal {
        uint256 sellAmount = IERC20(XETH_ADDRESS).balanceOf(address(this));
        IFxMarket(FX_MARKET).redeem(0, sellAmount, to, 0);
    }
    function _redeemfeth(
        address to
    ) internal {
        uint256 sellAmount = IERC20(FETH_ADDRESS).balanceOf(address(this));
        IFxMarket(FX_MARKET).redeem(sellAmount, 0, to, 0);
    }

    function sellBase(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        (bool isXeth, bool isMint) = abi.decode(moreInfo, (bool, bool));
        if (isXeth) {
            if (isMint) {
                _mintxeth(to);
            } else {
                _redeemxeth(to);
            }
        } else {
            if (isMint) {
                _mintfeth(to);
            } else {
                _redeemfeth(to);
            }
        }
    }

    function sellQuote(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        (bool isXeth, bool isMint) = abi.decode(moreInfo, (bool, bool));
        if (isXeth) {
            if (isMint) {
                _mintxeth(to);
            } else {
                _redeemxeth(to);
            }
        } else {
            if (isMint) {
                _mintfeth(to);
            } else {
                _redeemfeth(to);
            }
        }
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IPSM.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniversalERC20.sol";
import "../libraries/SafeERC20.sol";

contract PSMAdapter is IAdapter {

    address public immutable PSM_ADDRESS;
    address public immutable USDC_ADDRESS;
    address public immutable DAI_ADDRESS;

    uint256 constant SZABO = 10 ** 12;
    address constant PSM_USDC = 0x0A59649758aa4d66E25f08Dd01271e891fe52199;

    constructor(address _dss_psm, address _usdc, address _dai) {
        PSM_ADDRESS = _dss_psm;
        USDC_ADDRESS = _usdc;
        DAI_ADDRESS = _dai;
    }


    function _psmSwap(
        address to,
        address,
        bytes memory moreInfo
    ) internal {
        IPSM dssPsm = IPSM(PSM_ADDRESS);
        (address sourceToken, address targetToken) = abi.decode(
            moreInfo,
            (address, address)
        );
        uint256 sellAmount = IERC20(sourceToken).balanceOf(address(this));
        if (sourceToken == USDC_ADDRESS) {
            require(targetToken == DAI_ADDRESS, "PSMAdapter: no support token");
            // approve origin psm
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                PSM_USDC,
                sellAmount
            );
            // usdc - dai
            dssPsm.sellGem(address(this),sellAmount);
        } else if (sourceToken == DAI_ADDRESS) {
            require(targetToken == USDC_ADDRESS, "PSMAdapter: no support token");
            // approve dsspsm
            SafeERC20.safeApprove(
                IERC20(sourceToken),
                PSM_ADDRESS,
                sellAmount
            );
            // dai - usdc decimal need to be 6
            dssPsm.buyGem(address(this),sellAmount / SZABO);
        } else {
            revert("PSMAdapter: no support token");
        }
        // approve 0
        SafeERC20.safeApprove(
            IERC20(sourceToken),
            PSM_ADDRESS,
            0
        );
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(targetToken),
                to,
                IERC20(targetToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _psmSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _psmSwap(to, pool, moreInfo);
    }

}

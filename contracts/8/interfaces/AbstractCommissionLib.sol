// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract AbstractCommissionLib {
    struct CommissionInfo {
        bool isFromTokenCommission;
        bool isToTokenCommission;
        uint256 commissionRate;
        address refererAddress;
        address token;
        uint256 commissionRate2;
        address refererAddress2;
        bool isToBCommission;
    }

    function _getCommissionInfo()
        internal
        pure
        virtual
        returns (CommissionInfo memory commissionInfo);

    function _doCommissionFromToken(
        CommissionInfo memory commissionInfo,
        address payer,
        address receiver,
        uint256 inputAmount
    ) internal virtual returns (address, uint256);

    function _doCommissionToToken(
        CommissionInfo memory commissionInfo,
        address receiver,
        uint256 balanceBefore
    ) internal virtual returns (uint256);

    function _validateCommissionInfo(
        CommissionInfo memory commissionInfo,
        address fromToken,
        address toToken
    ) internal pure virtual;
}

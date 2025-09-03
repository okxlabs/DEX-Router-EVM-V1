// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Currency} from "../types/Currency.sol";
import {PoolId} from "../types/PoolId.sol";
import {PoolKey} from "../types/PoolKey.sol";

interface IProtocolFees {
    error ProtocolFeeTooLarge(uint24 fee);

    error InvalidCaller();

    error ProtocolFeeCurrencySynced();

    event ProtocolFeeControllerUpdated(address indexed protocolFeeController);

    event ProtocolFeeUpdated(PoolId indexed id, uint24 protocolFee);

    function protocolFeesAccrued(Currency currency) external view returns (uint256 amount);

    function setProtocolFee(PoolKey memory key, uint24 newProtocolFee) external;

    function setProtocolFeeController(address controller) external;

    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        returns (uint256 amountCollected);

    function protocolFeeController() external view returns (address);
}

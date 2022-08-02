
/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;


interface IMstable {

    /** @dev Swapping */
    function swap(
        address _input,
        address _output,
        uint256 _quantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 output);

}
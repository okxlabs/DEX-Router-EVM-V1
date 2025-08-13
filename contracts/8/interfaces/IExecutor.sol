// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IDexRouter.sol";

interface IExecutor  is IDexRouter {

    
    function execute(
        address payer,
        address receiver,
        BaseRequest memory baseRequest,
        uint256 toTokenExpectedAmount,
        uint256 maxConsumeAmount,
        bytes memory data
    ) external returns (uint256);

    function preview(BaseRequest memory baseRequest, uint256 toTokenExpectedAmount, bytes memory data) external returns (uint256);
}
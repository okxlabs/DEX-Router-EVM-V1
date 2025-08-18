// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IDexRouter.sol";

interface IExecutor  is IDexRouter {

    
    function execute(
        address payer,
        address receiver,
        BaseRequest memory baseRequest,
        ExecutorInfo memory executorInfo
    ) external returns (uint256);

    function preview(BaseRequest memory baseRequest, ExecutorInfo memory executorInfo) external returns (uint256);
}
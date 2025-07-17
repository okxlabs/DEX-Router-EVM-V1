// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}

enum GasMode {
    VOID,
    CLAIMABLE
}

interface IBlast {
    // configure
    function configureContract(
        address contractAddress,
        YieldMode _yield,
        GasMode gasMode,
        address governor
    ) external;
    function configure(
        YieldMode _yield,
        GasMode gasMode,
        address governor
    ) external;

    // base configuration options
    function configureClaimableYield() external;
    function configureClaimableYieldOnBehalf(address contractAddress) external;
    function configureAutomaticYield() external;
    function configureAutomaticYieldOnBehalf(address contractAddress) external;
    function configureVoidYield() external;
    function configureVoidYieldOnBehalf(address contractAddress) external;
    function configureClaimableGas() external;
    function configureClaimableGasOnBehalf(address contractAddress) external;
    function configureVoidGas() external;
    function configureVoidGasOnBehalf(address contractAddress) external;
    function configureGovernor(address _governor) external;
    function configureGovernorOnBehalf(
        address _newGovernor,
        address contractAddress
    ) external;

    // claim yield
    function claimYield(
        address contractAddress,
        address recipientOfYield,
        uint256 amount
    ) external returns (uint256);
    function claimAllYield(
        address contractAddress,
        address recipientOfYield
    ) external returns (uint256);

    // claim gas
    function claimAllGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256);
    function claimGasAtMinClaimRate(
        address contractAddress,
        address recipientOfGas,
        uint256 minClaimRateBips
    ) external returns (uint256);
    function claimMaxGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256);
    function claimGas(
        address contractAddress,
        address recipientOfGas,
        uint256 gasToClaim,
        uint256 gasSecondsToConsume
    ) external returns (uint256);

    // read functions
    function readClaimableYield(
        address contractAddress
    ) external view returns (uint256);
    function readYieldConfiguration(
        address contractAddress
    ) external view returns (uint8);
    function readGasParams(
        address contractAddress
    )
        external
        view
        returns (
            uint256 etherSeconds,
            uint256 etherBalance,
            uint256 lastUpdated,
            GasMode
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IShell {

    function originSwap (
        address _origin,
        address _target,
        uint _originAmount,
        uint _minTargetAmount,
        uint _deadline
    ) external returns (
        uint
    );

    function originSwapTo (
        address _origin,
        address _target,
        uint _originAmount,
        uint _minTargetAmount,
        uint _deadline,
        address _recipient
    ) external returns (
        uint targetAmount_
    );

    function viewOriginSwap (
        address _origin,
        address _target,
        uint _originAmount
    ) external view returns (
        uint targetAmount_
    );

    function targetSwap (
        address _origin,
        address _target,
        uint _maxOriginAmount,
        uint _targetAmount,
        uint _deadline
    ) external returns (
        uint originAmount_
    );

    function tansferByTarget (
        address _origin,
        address _target,
        uint _maxOriginAmount,
        uint _targetAmount,
        address _recipient,
        uint _deadline
    ) external returns (
        uint originAmount_
    );

    function viewTargetSwap (
        address _origin,
        address _target,
        uint _targetAmount
    ) external view returns (
        uint originAmount_
    );

    function proportionalDeposit (
        uint _totalStablecoins,
        uint _deadline
    ) external returns (
        uint shellsMinted_,
        uint[] memory deposits_
    );

    function viewProportionalDeposit (
        uint _totalStablecoins
    ) external view returns (
        uint shellsToMint_,
        uint[] memory depositsToMake_
    );

    function selectiveDeposit (
        address[] calldata _derivatives,
        uint[] calldata _amounts,
        uint _minShells,
        uint _deadline
    ) external returns (
        uint shellsMinted_
    );

    function viewSelectiveDeposit (
        address[] calldata _derivatives,
        uint[] calldata _amounts
    ) external view returns (
        uint shellsToMint_
    );

    function proportionalWithdraw (
        uint _shellTokens,
        uint _deadline
    ) external returns (
        uint[] memory withdrawals_
    );

    function viewProportionalWithdraw (
        uint _shellTokens
    ) external view returns (
        uint[] memory withdrawalsToMake_
    );

    function viewSelectiveDeposit (
        address[] calldata _flavors,
        uint[] calldata _amounts,
        uint _minShells,
        uint _deadline
    ) external view returns (uint);

    function selectiveWithdraw (
        address[] calldata _derivatives,
        uint[] calldata _amounts,
        uint _maxShells,
        uint _deadline
    ) external returns (
        uint shellsBurned_
    );

    function viewSelectiveWithdraw (
        address[] calldata _derivatives,
        uint[] calldata _amounts
    ) external view returns (
        uint shellsToBurn_
    );

    function partitionedWithdraw (
        address[] calldata _derivatives,
        uint[] calldata _amounts
    ) external returns (
        uint[] memory withdrawals_
    );

    function viewPartitionClaims (
        address _addr
    ) external view returns (
        uint[] memory claims_
    );

    function viewProportionalWithdraw (
        uint shellTokens,
        uint deadline
    ) external view returns (uint[] memory);

    function owner () external view returns (address);

    function includeAsset (
        address _numeraire,
        address _numeraireAssimilator,
        address _reserve,
        address _reserveAssimilator,
        uint _weight
    ) external;

    function includeAssimilator (
        address _derivative,
        address _numeraire,
        address _reserve,
        address _assimilator
    ) external;

    function excludeAssimilator (
        address _assimilator
    ) external;

    function setFrozen (
        bool _toFreezeOrNotToFreeze
    ) external;

    function transferOwnership (
        address _newOwner
    ) external;

    function viewShell () external view returns (
        uint alpha_,
        uint beta_,
        uint delta_,
        uint epsilon_,
        uint lambda_,
        uint omega_
    );

    function setParams (
        uint _alpha,
        uint _beta,
        uint _deltaDerivative,
        uint _epsilon,
        uint _lambda
    ) external;

    function prime () external;

    function liquidity () external view returns (
        uint total_,
        uint[] memory individual_
    );

    function name () external view returns (string memory);
    function symbol () external view returns (string memory);

    function shell () external view returns (
        int128 alpha,
        int128 beta,
        int128 delta,
        int128 epsilon,
        int128 lambda,
        int128 omega,
        uint totalSupply
    );

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint);

    function balanceOf(
        address account
    ) external view returns (uint);

    function transfer(
        address recipient,
        uint amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function approve(
        address spender,
        uint amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint);

    event ParametersSet(
        uint256 alpha,
        uint256 beta,
        uint256 delta,
        uint256 epsilon,
        uint256 lambda,
        uint256 omega
    );

    event AssetIncluded(
        address numeraire,
        address reserve,
        uint weight
    );

    event AssimilatorIncluded(
        address derivative,
        address numeraire,
        address reserve,
        address assimilator
    );

    event PartitionRedeemed(
        address token,
        address redeemer,
        uint value
    );

    event PoolPartitioned(
        bool partitioned
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );

    event ShellsMinted(
        address indexed minter,
        uint amount,
        address[] indexed coins,
        uint[] amounts
    );

    event ShellsBurned(
        address indexed burner,
        uint amount,
        address[] indexed coins,
        uint[] amounts
    );

    event ShellsBurned(
        address indexed burner,
        uint amount
    );

    event OwnershipTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );

    event Trade(
        address indexed trader,
        address indexed origin,
        address indexed target,
        uint originAmount,
        uint targetAmount
    );

    event FrozenSet(
        bool isFrozen
    );

}
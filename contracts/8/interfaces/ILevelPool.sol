pragma solidity >=0.8.0;

import {DataTypes} from "../libraries/LevelFinanceDataType.sol";

interface ILevelPool {
    struct TokenWeight {
        address token;
        uint256 weight;
    }

    struct RiskConfig {
        address tranche;
        uint256 riskFactor;
    }

    function isValidLeverageTokenPair(
        address _indexToken,
        address _collateralToken,
        DataTypes.Side _side,
        bool _isIncrease
    ) external view returns (bool);

    function canSwap(address _tokenIn, address _tokenOut) external view returns (bool);

    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        DataTypes.Side _side
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        DataTypes.Side _side,
        address _receiver
    ) external;

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to, bytes calldata extradata)
        external;

    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external;

    function removeLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount, uint256 _minOut, address _to)
        external;

    function getPoolAsset(address _token) external view returns (DataTypes.AssetInfo memory);

    function getAllAssets() external view returns (address[] memory tokens, bool[] memory isStable);

    function getAllTranches() external view returns (address[] memory);

    // =========== EVENTS ===========

    event SetOrderManager(address indexed orderManager);
    event IncreasePosition(
        bytes32 indexed key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        DataTypes.Side side,
        uint256 indexPrice,
        uint256 feeValue
    );
    event UpdatePosition(
        bytes32 indexed key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 indexed key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        DataTypes.Side side,
        uint256 indexPrice,
        int256 pnl,
        uint256 feeValue
    );
    event ClosePosition(
        bytes32 indexed key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 indexed key,
        address account,
        address collateralToken,
        address indexToken,
        DataTypes.Side side,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice,
        int256 pnl,
        uint256 feeValue
    );
    event DaoFeeWithdrawn(address indexed token, address recipient, uint256 amount);
    event FeeDistributorSet(address indexed feeDistributor);
    event LiquidityAdded(
        address indexed tranche, address indexed sender, address token, uint256 amount, uint256 lpAmount, uint256 fee
    );
    event LiquidityRemoved(
        address indexed tranche, address indexed sender, address token, uint256 lpAmount, uint256 amountOut, uint256 fee
    );
    event TokenWeightSet(TokenWeight[]);
    event Swap(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        uint256 priceIn,
        uint256 priceOut
    );
    event PositionFeeSet(uint256 positionFee, uint256 liquidationFee);
    event DaoFeeSet(uint256 value);
    event InterestAccrued(address indexed token, uint256 borrowIndex);
    event MaxLeverageChanged(uint256 maxLeverage);
    event TokenWhitelisted(address indexed token);
    event TokenDelisted(address indexed token);
    event OracleChanged(address indexed oldOracle, address indexed newOracle);
    event InterestRateSet(uint256 interestRate, uint256 stableCoinInterestRate, uint256 interval);
    event InterestRateModelSet(address indexed token, address interestRateModel);
    event PoolHookChanged(address indexed hook);
    event TrancheAdded(address indexed lpToken);
    event TokenRiskFactorUpdated(address indexed token);
    event PnLDistributed(address indexed asset, address indexed tranche, int256 pnl);
    event MaintenanceMarginChanged(uint256 ratio);
    event MaxGlobalPositionSizeSet(address indexed token, uint256 maxLongRatios, uint256 maxShortSize);
    event PoolControllerChanged(address controller);
    event AssetRebalanced();
    event LiquidityCalculatorSet(address feeModel);
    event VirtualPoolValueRefreshed(uint256 value);
    event MaxLiquiditySet(address token, uint256 value);

    // ========== ERRORS ==============

    error UpdateCauseLiquidation();
    error InvalidLeverageTokenPair();
    error InvalidLeverage();
    error InvalidPositionSize();
    error OrderManagerOnly();
    error UnknownToken();
    error AssetNotListed();
    error InsufficientPoolAmount();
    error ReserveReduceTooMuch();
    error SlippageExceeded();
    error ValueTooHigh();
    error InvalidInterval();
    error PositionNotLiquidated();
    error ZeroAmount();
    error ZeroAddress();
    error RequireAllTokens();
    error DuplicateToken();
    error FeeDistributorOnly();
    error InvalidMaxLeverage();
    error InvalidSwapPair();
    error InvalidTranche();
    error TrancheAlreadyAdded();
    error RemoveLiquidityTooMuch();
    error CannotDistributeToTranches();
    error PositionNotExists();
    error MaxNumberOfTranchesReached();
    error TooManyTokenAdded();
    error AddLiquidityNotAllowed();
    error MaxGlobalShortSizeExceeded();
    error NotApplicableForStableCoin();
    error MaxLiquidityReach();
}
pragma solidity >=0.8.0;

library DataTypes {
    enum Side {
        LONG,
        SHORT
    }

    struct PositionIdentifier {
        address owner;
        address indexToken;
        address collateralToken;
        Side side;
    }

    enum UpdatePositionType {
        INCREASE,
        DECREASE
    }

    struct UpdatePositionRequest {
        uint256 sizeChange;
        uint256 collateral;
        UpdatePositionType updateType;
        Side side;
    }

    enum OrderType {
        MARKET,
        LIMIT
    }

    enum OrderStatus {
        OPEN,
        FILLED,
        EXPIRED,
        CANCELLED
    }

    struct LeverageOrder {
        address owner;
        address indexToken;
        address collateralToken;
        OrderStatus status;
        address payToken;
        bool triggerAboveThreshold;
        uint256 price;
        uint256 executionFee;
        uint256 submissionBlock;
        uint256 expiresAt;
    }

    struct SwapOrder {
        address owner;
        address tokenIn;
        address tokenOut;
        OrderStatus status;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 price;
        uint256 executionFee;
    }

    struct AssetInfo {
        /// @notice amount of token deposited (via add liquidity or increase long position)
        uint256 poolAmount;
        /// @notice amount of token reserved for paying out when user decrease long position
        uint256 reservedAmount;
        /// @notice total borrowed (in USD) to leverage
        uint256 guaranteedValue;
        /// @notice total size of all short positions
        uint256 totalShortSize;
        /// @notice average entry price of all short positions
        uint256 averageShortPrice;
    }

    struct Position {
        /// @dev contract size is evaluated in dollar
        uint256 size;
        /// @dev collateral value in dollar
        uint256 collateralValue;
        /// @dev contract size in indexToken
        uint256 reserveAmount;
        /// @dev average entry price
        uint256 entryPrice;
        /// @dev last cumulative interest rate
        uint256 borrowIndex;
    }
}
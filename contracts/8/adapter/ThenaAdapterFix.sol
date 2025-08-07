// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/ISolidly.sol";
import "../interfaces/IERC20.sol";

/**
 * @title ThenaAdapterFix
 * @notice Adapter for Thena DEX swaps with K-invariant protection for stable pools. When the initial getAmountOut 
 * result violates the K-invariant check, the adapter performs binary search between 95% of the original result 
 * and the full result to find the maximum safe amountOut that preserves pool stability.
 * @dev This contract implements enhanced safety mechanisms for stable pool swaps by validating the K-invariant 
 * (K = x³y + y³x) before execution. For volatile pools, it executes direct swaps without additional validation.
 * The binary search algorithm ensures optimal amountOut while maintaining mathematical correctness of the AMM.
 */
contract ThenaAdapterFix is IAdapter {
    uint256 private constant MAX_ITERATIONS = 50; // Max iteration times
    uint256 private constant PRECISION = 1e18; // Precision base

    struct PoolInfo {
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 reserveIn;
        uint256 reserveOut;
        address tokenIn;
        address tokenOut;
    }

    struct SearchResult {
        uint256 amountOut;
        uint256 iterations;
    }

    event AmountOutAdjusted(
        address indexed pool,
        uint256 originalAmountOut,
        uint256 adjustedAmountOut,
        uint256 iterations
    );

    /**
     * @notice fromToken = token0, toToken = token1
     * @param to receiver address
     * @param pool pool address
     * @param moreInfo encoded fee and isStable
     */
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint256 fee, bool isStable) = abi.decode(moreInfo, (uint256, bool));
        _executeSwap(pool, fee, true, to, isStable);
    }

    /**
     * @notice fromToken = token1, toToken = token0
     * @param to receiver address
     * @param pool pool address
     * @param moreInfo encoded fee and isStable
     */
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        (uint256 fee, bool isStable) = abi.decode(moreInfo, (uint256, bool));
        _executeSwap(pool, fee, false, to, isStable);
    }

    /**
     * @notice execute swap
     * @param pool pool address
     * @param fee fee
     * @param zeroForOne true if fromToken = token0, false if fromToken = token1
     * @param to receiver address
     * @param isStable true if pool is stable, false if pool is unstable
     */
    function _executeSwap(
        address pool,
        uint256 fee,
        bool zeroForOne,
        address to,
        bool isStable
    ) internal {
        PoolInfo memory poolInfo = PoolInfo({
            token0: address(0),
            token1: address(0),
            reserve0: 0,
            reserve1: 0,
            reserveIn: 0,
            reserveOut: 0,
            tokenIn: address(0),
            tokenOut: address(0)
        });
        poolInfo.token0 = IPair(pool).token0();
        poolInfo.token1 = IPair(pool).token1();
        (poolInfo.reserve0, poolInfo.reserve1,) = IPair(pool).getReserves();
        poolInfo.tokenIn = zeroForOne ? poolInfo.token0 : poolInfo.token1;
        poolInfo.tokenOut = zeroForOne ? poolInfo.token1 : poolInfo.token0;
        poolInfo.reserveIn = zeroForOne ? poolInfo.reserve0 : poolInfo.reserve1;
        poolInfo.reserveOut = zeroForOne ? poolInfo.reserve1 : poolInfo.reserve0;
        uint256 amountIn = IERC20(poolInfo.tokenIn).balanceOf(pool) - poolInfo.reserveIn;
        uint256 amountOut = IPair(pool).getAmountOut(
            amountIn,
            poolInfo.tokenIn
        );

        if (!isStable) {
            // unstable pair
            _swap(pool, zeroForOne, amountOut, to);
        } else {
            // stable pair
            SearchResult memory searchResult = _binarySearchSafeAmount(
                poolInfo.tokenIn,
                poolInfo.tokenOut,
                poolInfo.reserveIn,
                poolInfo.reserveOut,
                amountIn,
                fee,
                amountOut
            );
            _swap(pool, zeroForOne, searchResult.amountOut, to);
            if (searchResult.amountOut != amountOut) {
                emit AmountOutAdjusted(pool, amountOut, searchResult.amountOut, searchResult.iterations);
            }
        }
    }

    function _swap(
        address pool,
        bool zeroForOne,
        uint256 amountOut,
        address to
    ) internal {
        (uint256 amount0Out, uint256 amount1Out) = zeroForOne
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));

        IPair(pool).swap(amount0Out, amount1Out, to, "");
    }

    function _binarySearchSafeAmount(
        address tokenIn,
        address tokenOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn,
        uint256 fee,
        uint256 originalAmountOut
    ) internal view returns (SearchResult memory) {
        uint256 decimals0 = 10 ** IERC20(tokenIn).decimals();
        uint256 decimals1 = 10 ** IERC20(tokenOut).decimals();

        uint256 kBefore = _calculateKWithDecimals(
            reserveIn,
            reserveOut,
            decimals0,
            decimals1
        );
        
        uint256 amountInAfterFee = amountIn - (amountIn * fee) / 10000;
        
        uint256 kAfter = _calculateKWithDecimals(
            reserveIn + amountInAfterFee,
            reserveOut - originalAmountOut,
            decimals0,
            decimals1
        );
        
        if (kAfter >= kBefore) {
            return SearchResult({
                amountOut: originalAmountOut,
                iterations: 0
            });
        } else {
            return _performBinarySearchWithFee(
                reserveIn,
                reserveOut,
                amountInAfterFee,
                originalAmountOut,
                kBefore,
                decimals0,
                decimals1
            );
        }
    }

    /**
     * @notice Execute binary search logic (with fee handling)
     */
    function _performBinarySearchWithFee(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountInAfterFee,
        uint256 originalAmountOut,
        uint256 kBefore,
        uint256 decimals0,
        uint256 decimals1
    ) internal pure returns (SearchResult memory) {
        uint256 left = (originalAmountOut * 95) / 100;
        uint256 right = originalAmountOut;
        uint256 bestAmount = left;

        uint256 i;
        for (; i < MAX_ITERATIONS; i++) {
            uint256 mid = (left + right) / 2;
            uint256 kAfter = _calculateKWithDecimals(
                reserveIn + amountInAfterFee,
                reserveOut - mid,
                decimals0,
                decimals1
            );

            if (kAfter >= kBefore) {
                bestAmount = mid;
                left = mid + 1;
            } else {
                right = mid - 1;
            }

            if (left > right) break;
        }

        return SearchResult({
            amountOut: bestAmount,
            iterations: i
        });
    }

    /**
     * @notice Calculate K value for stable pair, same as Solidly Pair
     */
    function _calculateKWithDecimals(
        uint256 x,
        uint256 y,
        uint256 decimals0,
        uint256 decimals1
    ) internal pure returns (uint256) {
        // Stable pool: K = x³y + y³x
        uint256 _x = (x * 1e18) / decimals0;
        uint256 _y = (y * 1e18) / decimals1;
        uint256 _a = (_x * _y) / 1e18;
        uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return (_a * _b) / 1e18;
    }
}

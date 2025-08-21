// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IExecutor.sol";
import "../libraries/CommonUtils.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniV2ExactOutExecutor is IExecutor, CommonUtils {
    uint256 private constant _DENOMINATOR = 1_000_000_000;
    uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
    uint256 private constant _NUMERATOR_OFFSET = 160;

    struct AmountInfo {
        uint256 amountIn;
        uint256 amountOut;
        address pool;
        bool isZeroForOne;
        bool unWrapWETH;
    }

    function execute(
        address payer,
        address receiver,
        BaseRequest memory baseRequest,
        ExecutorInfo memory executorInfo
    ) external returns (uint256, uint256) {
        (bytes32[] memory pools) = abi.decode(executorInfo.executorData, (bytes32[]));
        AmountInfo[] memory amountInfos = _calculate(
            address(uint160(baseRequest.fromToken & _ADDRESS_MASK)),
            baseRequest.fromTokenAmount,
            executorInfo.toTokenExpectedAmount,
            pools
        );
        for (uint256 i = 0; i < amountInfos.length; i++) {
            if (amountInfos[i].isZeroForOne) {
                IUniswapV2Pair(amountInfos[i].pool).swap(
                    0, amountInfos[i].amountOut, _getAssetTo(i, amountInfos, receiver), ""
                );
            } else {
                IUniswapV2Pair(amountInfos[i].pool).swap(
                    amountInfos[i].amountOut, 0, _getAssetTo(i, amountInfos, receiver), ""
                );
            }
        }
        // unwrap weth
        if (amountInfos[amountInfos.length - 1].unWrapWETH) {
            IWETH(_WETH).withdraw(amountInfos[amountInfos.length - 1].amountOut);
            (bool success,) = payable(receiver).call{value: amountInfos[amountInfos.length - 1].amountOut}("");
            require(success, "transfer failed");
        }
        // refund from token
        address fromToken = address(uint160(baseRequest.fromToken & _ADDRESS_MASK));
        if (fromToken == _ETH) {
            // withdraw from weth
            uint256 amount = IERC20(_WETH).balanceOf(address(this));
            IWETH(_WETH).withdraw(amount);
            (bool success,) = payable(payer).call{value: amount}("");
            require(success, "refund failed");
        } else {
            uint256 amount = IERC20(fromToken).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(fromToken), payer, amount);
        }

        return (amountInfos[0].amountIn, amountInfos[amountInfos.length - 1].amountOut);
    }

    function _getAssetTo(uint256 i, AmountInfo[] memory amountInfos, address receiver) internal returns (address) {
        if (i < amountInfos.length - 1) {
            return amountInfos[i + 1].pool;
        }
        if (amountInfos[i].unWrapWETH) {
            return address(this);
        } else {
            return receiver;
        }
    }

    // function preview(BaseRequest memory baseRequest, ExecutorInfo memory executorInfo)
    //     external
    //     returns (uint256 fromTokenAmount)
    // {
    //     (bytes32[] memory pools) = abi.decode(executorInfo.executorData, (bytes32[]));
    //     AmountInfo[] memory amountInfos = _calculate(
    //         address(uint160(baseRequest.fromToken & _ADDRESS_MASK)),
    //         baseRequest.fromTokenAmount,
    //         executorInfo.toTokenExpectedAmount,
    //         pools
    //     );
    //     return amountInfos[0].amountIn;
    // }

    function _calculate(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 toTokenExpectedAmount,
        bytes32[] memory pools
    ) internal returns (AmountInfo[] memory amountInfos) {
        amountInfos = new AmountInfo[](pools.length);
        uint256 currentAmountOut = toTokenExpectedAmount;
        
        // Calculate backwards from the last pool to the first
        for (uint256 i = pools.length; i > 0; i--) {
            uint256 poolIndex = i - 1;
            amountInfos[poolIndex] = _getAmountInfo(pools[poolIndex], currentAmountOut);
            currentAmountOut = amountInfos[poolIndex].amountIn;
        }
        return amountInfos;
    }

    function _getAmountInfo(bytes32 pool, uint256 amountOut)
        internal
        returns (AmountInfo memory)
    {
        address poolAddress = address(uint160(uint256(pool) & _ADDRESS_MASK));
        uint256 numerator = (uint256(pool) & _NUMERATOR_MASK) >> _NUMERATOR_OFFSET;
        bool isZeroForOne = uint256(pool) & _REVERSE_MASK == 0;
        bool unWrapWETH = uint256(pool) & _WETH_MASK != 0;
        (uint256 r0, uint256 r1,) = IUniswapV2Pair(poolAddress).getReserves();
        uint256 reserveIn = isZeroForOne ? r0 : r1;
        uint256 reserveOut = isZeroForOne ? r1 : r0;
        uint256 amountIn = _getAmountIn(reserveIn, reserveOut, amountOut, numerator);
        return AmountInfo({
            amountIn: amountIn,
            amountOut: amountOut,
            pool: poolAddress,
            isZeroForOne: isZeroForOne,
            unWrapWETH: unWrapWETH
        });
    }

    function _getAmountIn(uint256 reserveIn, uint256 reserveOut, uint256 amountOut, uint256 numerator)
        internal
        returns (uint256)
    {
        return (amountOut * reserveIn * _DENOMINATOR) / ((reserveOut - amountOut) * numerator) + 1;
    }

    receive() external payable {}
}

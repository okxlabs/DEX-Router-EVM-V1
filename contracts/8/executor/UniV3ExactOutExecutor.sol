// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IExecutor.sol";
import "../libraries/CommonUtils.sol";
import "../interfaces/IUniV3.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract UniV3ExactOutExecutor is IExecutor, CommonUtils {
    bytes32 private constant _POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54; // Pool init code hash
    bytes32 private constant _FF_FACTORY = 0xff1F98431c8aD98523631AE4a59f267346ea31F9840000000000000000000000; // Factory address
    // concatenation of token0(), token1() fee(), transfer() and claimTokens() selectors
    bytes32 private constant _SELECTORS = 0x0dfe1681d21220a7ddca3f43a9059cbb0a5ea466000000000000000000000000;
    // concatenation of withdraw(uint),transfer()
    bytes32 private constant _SELECTORS2 = 0x2e1a7d4da9059cbb000000000000000000000000000000000000000000000000;
    bytes32 private constant _SELECTORS3 = 0xa9059cbb70a08231000000000000000000000000000000000000000000000000;
    uint160 private constant _MIN_SQRT_RATIO = 4_295_128_739 + 1;
    uint160 private constant _MAX_SQRT_RATIO = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_342 - 1;
    bytes32 private constant _SWAP_SELECTOR = 0x128acb0800000000000000000000000000000000000000000000000000000000; // Swap function selector
    uint256 private constant _INT256_MAX = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; // Maximum int256
    uint256 private constant _INT256_MIN = 0x8000000000000000000000000000000000000000000000000000000000000000; // Minimum int256

    function execute(
        address payer,
        address receiver,
        BaseRequest memory baseRequest,
        ExecutorInfo memory executorInfo
    ) external returns (uint256) {
        (uint256[] memory pools) = abi.decode(executorInfo.executorData, (uint256[]));
        address middleReceiver = pools[pools.length - 1] & _WETH_MASK != 0 ? address(this) : receiver;
        _swap(executorInfo.toTokenExpectedAmount, pools, pools.length, middleReceiver, false);
        if (pools[pools.length - 1] & _WETH_MASK != 0) {
            IWETH(_WETH).withdraw(IERC20(_WETH).balanceOf(address(this)));
            (bool success, ) = payable(receiver).call{value: address(this).balance}("");
            require(success, "transfer native token failed");
        }
        return executorInfo.toTokenExpectedAmount;
    }

    function preview(BaseRequest memory baseRequest, ExecutorInfo memory executorInfo)
        external
        returns (uint256 fromTokenAmount)
    {
        (uint256[] memory pools) = abi.decode(executorInfo.executorData, (uint256[]));
        uint256 amount = _swap(executorInfo.toTokenExpectedAmount, pools, pools.length, address(this), true);
        return amount;
    }


    function _swap(
        uint256 toTokenExpectedAmount,
        uint256[] memory pools,
        uint256 i,
        address receiver,
        bool isPreview
    ) internal returns (uint256) {
        uint256 pool = pools[i - 1];
        address poolAddress = address(uint160(pool & _ADDRESS_MASK));
        bool zeroForOne = (pool & _ONE_FOR_ZERO_MASK) == 0;
        // Specify the amount as a negative value to indicate exact output.
        int256 amountSpecified = -SafeCast.toInt256(toTokenExpectedAmount);
        bytes memory callbackData = abi.encode(pools, i - 1, receiver, isPreview);
        (int256 amount0, int256 amount1) = IUniV3(poolAddress).swap(
            receiver,
            zeroForOne,
            amountSpecified,
            zeroForOne ? _MIN_SQRT_RATIO : _MAX_SQRT_RATIO,
            callbackData
        );
        return zeroForOne ? uint256(amount0) : uint256(amount1);
    }


    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes memory data) external {
        (uint256[] memory pools, uint256 i, address receiver, bool isPreview) =
            abi.decode(data, (uint256[], uint256, address, bool));
        address poolAddress = address(uint160(pools[i] & _ADDRESS_MASK));
        require(msg.sender == poolAddress, "not pool");
        uint amountToPay = amount0 > 0 ? uint256(amount0) : uint256(amount1);
        uint amountToReceive = amount0 < 0 ? uint256(amount0) : uint256(amount1);
        address toTokenPay = amount0 > 0 ? IUniV3(poolAddress).token0() : IUniV3(poolAddress).token1();
        address toTokenReceive = amount0 < 0 ? IUniV3(poolAddress).token0() : IUniV3(poolAddress).token1();
        SafeERC20.safeTransfer(IERC20(toTokenReceive), receiver, amountToReceive);
        bool zeroForOne = (pools[i] & _ONE_FOR_ZERO_MASK) == 0;


        if (i == 0) {
            if (isPreview) {
                assembly {
                    mstore(0, amountToPay)
                    revert(0, 32)
                }
            }
            SafeERC20.safeTransfer(IERC20(toTokenPay), msg.sender, amountToPay);
        } else {
            _swap(amountToPay, pools, i - 1, poolAddress, isPreview);
        }
    }
}

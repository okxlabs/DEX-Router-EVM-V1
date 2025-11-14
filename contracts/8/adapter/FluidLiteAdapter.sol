// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IAdapter.sol";
import "../interfaces/IFluidDexLite.sol";
import "../interfaces/IFluidDexLiteCallback.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";

/// @title FluidLiteAdapter
/// @notice FluidLiteAdapter is a contract that allows to swap between any token pair, including ETH.
/// @dev The tokenIn needs to be held before swap by adapter if it is not ETH. The FluidDexLite contract
/// will call back the adapter to pay the ERC20 tokenIn. And for ETH, just use the value to pay. If the
/// tokenOut is ETH, the ETH will directly be sent to the recipient. So the adapter needs to wrap the
/// ETH to WETH and send the WETH to `to` address if the tokenOut is ETH. The dexKey specifies the token
/// pair, so whether the tokenIn is ETH or WETH, the adapter receives the WETH but will wrap it to ETH
/// if the tokenIn in dexKey is ETH.
contract FluidLiteAdapter is IAdapter, IFluidDexLiteCallback {
    /// @dev specific flag for refund logic, "0x3ca20afc" is flexible and also used for commission, "ccc" mean refund
    uint256 constant ORIGIN_PAYER = 0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    uint256 constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WETH;
    address public immutable FLUID_DEX_LITE;

    constructor(address weth, address fluidDexLite) {
        WETH = weth;
        FLUID_DEX_LITE = fluidDexLite;
    }

    function sellBase(
        address to,
        address, // the only pool address is FLUID_DEX_LITE
        bytes memory moreInfo
    ) external override {
        _swap(to, moreInfo);
    }

    function sellQuote(
        address to,
        address, // the only pool address is FLUID_DEX_LITE
        bytes memory moreInfo
    ) external override {
        _swap(to, moreInfo);
    }

    function _swap(
        address to,
        bytes memory moreInfo
    ) internal {
        (IFluidDexLite.DexKey memory dexKey, bool swap0To1) = abi.decode(moreInfo, (IFluidDexLite.DexKey, bool));
        address tokenIn = swap0To1 ? dexKey.token0 : dexKey.token1;
        address tokenOut = swap0To1 ? dexKey.token1 : dexKey.token0;
        uint256 amountIn;

        // If the tokenIn is ETH, the adapter will receive the WETH and need to unwrap it to ETH
        if (tokenIn == ETH_ADDRESS) {
            amountIn = IWETH(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amountIn);
        } else {
            amountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        // Execute swap
        address receiver = tokenOut == ETH_ADDRESS ? address(this) : to; // If the tokenOut is ETH, the ETH needs to be wrapped to WETH and sent to the to address
        if (tokenIn == ETH_ADDRESS) {
            IFluidDexLite(FLUID_DEX_LITE).swapSingle{value: amountIn}(
                dexKey,
                swap0To1,
                int256(amountIn),
                0,
                receiver,
                false, // isCallback_
                "",
                ""
            );
        } else {
            IFluidDexLite(FLUID_DEX_LITE).swapSingle(
                dexKey,
                swap0To1,
                int256(amountIn),
                0,
                receiver,
                true, // isCallback_
                "",
                ""
            );
        }

        // If the tokenOut is ETH, the ETH needs to be wrapped to WETH and sent to the to address
        if (tokenOut == ETH_ADDRESS) {
            uint256 amountOut = address(this).balance;
            IWETH(WETH).deposit{value: amountOut}();
            IWETH(WETH).transfer(to, amountOut);
        }

        // Refund logic: if there is leftover fromToken, refund to payerOrigin
        address payerOrigin = _getPayerOrigin();
        if (tokenIn == ETH_ADDRESS) {
            uint256 amount = address(this).balance;
            if (amount > 0 && payerOrigin != address(0)) {
                (bool success, ) = payerOrigin.call{value: amount}("");
                require(success, "ETH transfer failed");
            }
        } else {
            uint256 amount = IERC20(tokenIn).balanceOf(address(this));
            if (amount > 0 && payerOrigin != address(0)) {
                SafeERC20.safeTransfer(IERC20(tokenIn), payerOrigin, amount);
            }
        }
    }

    function dexCallback(
        address token_,
        uint256 amount_,
        bytes calldata // data_
    ) external {
        require(token_ != ETH_ADDRESS, "ETH should not be sent by callback");
        require(msg.sender == FLUID_DEX_LITE, "only FluidDexLite can call back");
        SafeERC20.safeTransfer(IERC20(token_), msg.sender, amount_);
    }

    function _getPayerOrigin() internal pure returns (address payerOrigin) {
        uint256 _payerOrigin;
        assembly {
            // Get the total size of the calldata
            let size := calldatasize()
            // Load the last 32 bytes of the calldata, which is assumed to contain the payer origin
            // Assumption: The calldata is structured such that the payer origin is always at the end
            _payerOrigin := calldataload(sub(size, 32))
        }
        if ((_payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            payerOrigin = address(uint160(uint256(_payerOrigin) & ADDRESS_MASK));
        }
    }
}
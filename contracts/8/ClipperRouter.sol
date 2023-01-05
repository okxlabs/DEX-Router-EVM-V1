// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libraries/CommonUtils.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/RouterErrors.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IClipperExchangeInterface.sol";

/// @title Clipper router that allows to use `ClipperExchangeInterface` for swaps
contract ClipperRouter is CommonUtils {
    using SafeERC20 for IERC20;

    uint256 private constant _SIGNATURE_S_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _SIGNATURE_V_SHIFT = 255;
    bytes6 private constant _OKX_TAG_WITH_LENGTH_PREFIX = "\x03OKX";
    IERC20 private constant _ETH_IERC20 = IERC20(address(0));

    /// @notice Same as `clipperSwapTo` but calls permit first,
    /// allowing to approve token spending and make a swap in one transaction.
    /// @dev See tests for examples
    /// @param recipient Address that will receive swap funds
    /// @param srcToken Source token
    /// @param dstToken Destination token
    /// @param inputAmount Amount of source tokens to swap
    /// @param outputAmount Amount of destination tokens to receive
    /// @param goodUntil Timestamp until the swap will be valid
    /// @param r Clipper order signature (r part)
    /// @param vs Clipper order signature (vs part)
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @return returnAmount Amount of destination tokens received
    function clipperSwapToWithPermit(
        IClipperExchangeInterface clipperExchange,
        address payable recipient,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs,
        bytes calldata permit
    ) external returns(uint256 returnAmount) {
        srcToken.safePermit(permit);
        return clipperSwapTo(clipperExchange, recipient, srcToken, dstToken, inputAmount, outputAmount, goodUntil, r, vs);
    }

    /// @notice Same as `clipperSwapTo` but uses `msg.sender` as recipient
    /// @param srcToken Source token
    /// @param dstToken Destination token
    /// @param inputAmount Amount of source tokens to swap
    /// @param outputAmount Amount of destination tokens to receive
    /// @param goodUntil Timestamp until the swap will be valid
    /// @param r Clipper order signature (r part)
    /// @param vs Clipper order signature (vs part)
    /// @return returnAmount Amount of destination tokens received
    function clipperSwap(
        IClipperExchangeInterface clipperExchange,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external payable returns(uint256 returnAmount) {
        return clipperSwapTo(clipperExchange, payable(msg.sender), srcToken, dstToken, inputAmount, outputAmount, goodUntil, r, vs);
    }

    /// @notice Performs swap using Clipper exchange. Wraps and unwraps ETH if required.
    /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
    /// @param recipient Address that will receive swap funds
    /// @param srcToken Source token
    /// @param dstToken Destination token
    /// @param inputAmount Amount of source tokens to swap
    /// @param outputAmount Amount of destination tokens to receive
    /// @param goodUntil Timestamp until the swap will be valid
    /// @param r Clipper order signature (r part)
    /// @param vs Clipper order signature (vs part)
    /// @return returnAmount Amount of destination tokens received
    function clipperSwapTo(
        IClipperExchangeInterface clipperExchange,
        address payable recipient,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) public payable returns(uint256 returnAmount) {    
        bool srcETH = srcToken == _ETH_IERC20;
        if (srcETH) {
            if (msg.value != inputAmount) revert RouterErrors.InvalidMsgValue();
        } else if (srcToken == IERC20(_WETH)) {
            srcETH = true;
            if (msg.value != 0) revert RouterErrors.InvalidMsgValue();
            // _WETH.transferFrom(msg.sender, address(this), inputAmount);
            // _WETH.withdraw(inputAmount);
            address weth = address(_WETH);
            bytes4 transferFromSelector = IWETH(_WETH).transferFrom.selector;
            bytes4 withdrawSelector = IWETH(_WETH).withdraw.selector;
            /// @solidity memory-safe-assembly
            assembly { // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, transferFromSelector)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                mstore(add(ptr, 0x44), inputAmount)
                if iszero(call(gas(), weth, 0, ptr, 0x64, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }

                mstore(ptr, withdrawSelector)
                mstore(add(ptr, 0x04), inputAmount)
                if iszero(call(gas(), weth, 0, ptr, 0x24, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        } else {
            if (msg.value != 0) revert RouterErrors.InvalidMsgValue();
            srcToken.safeTransferFrom(msg.sender, address(clipperExchange), inputAmount);   
        }

        if (srcETH) {
            // clipperExchange.sellEthForToken{value: inputAmount}(address(dstToken), inputAmount, outputAmount, goodUntil, recipient, signature, _OKX_TAG);
            address clipper = address(clipperExchange);
            bytes4 selector = clipperExchange.sellEthForToken.selector;
            /// @solidity memory-safe-assembly
            assembly { // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), dstToken)
                mstore(add(ptr, 0x24), inputAmount)
                mstore(add(ptr, 0x44), outputAmount)
                mstore(add(ptr, 0x64), goodUntil)
                mstore(add(ptr, 0x84), recipient)
                mstore(add(ptr, 0xa4), add(27, shr(_SIGNATURE_V_SHIFT, vs)))
                mstore(add(ptr, 0xc4), r)
                mstore(add(ptr, 0xe4), and(vs, _SIGNATURE_S_MASK))
                mstore(add(ptr, 0x104), 0x120)
                mstore(add(ptr, 0x143), _OKX_TAG_WITH_LENGTH_PREFIX)                
                if iszero(call(gas(), clipper, inputAmount, ptr, 0x149, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        } else if (dstToken == _ETH_IERC20 || dstToken == IERC20(_WETH)) {
            // clipperExchange.sellTokenForEth(address(srcToken), inputAmount, outputAmount, goodUntil, recipient, signature, _OKX_TAG);
            address clipper = address(clipperExchange);
            bytes4 selector = clipperExchange.sellTokenForEth.selector;
            /// @solidity memory-safe-assembly
            assembly { // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), srcToken)
                mstore(add(ptr, 0x24), inputAmount)
                mstore(add(ptr, 0x44), outputAmount)
                mstore(add(ptr, 0x64), goodUntil)
                switch iszero(dstToken)
                case 1 {
                    mstore(add(ptr, 0x84), recipient)
                }
                default {
                    mstore(add(ptr, 0x84), address())
                }
                mstore(add(ptr, 0xa4), add(27, shr(_SIGNATURE_V_SHIFT, vs)))
                mstore(add(ptr, 0xc4), r)
                mstore(add(ptr, 0xe4), and(vs, _SIGNATURE_S_MASK))
                mstore(add(ptr, 0x104), 0x120)
                mstore(add(ptr, 0x143), _OKX_TAG_WITH_LENGTH_PREFIX)
                if iszero(call(gas(), clipper, 0, ptr, 0x149, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }

            if (dstToken == IERC20(_WETH)) {
                // _WETH.deposit{value: outputAmount}();
                // _WETH.transfer(recipient, outputAmount);
                address weth = address(_WETH);
                bytes4 depositSelector = IWETH(_WETH).deposit.selector;
                bytes4 transferSelector = IWETH(_WETH).transfer.selector;
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    let ptr := mload(0x40)

                    mstore(ptr, depositSelector)
                    if iszero(call(gas(), weth, outputAmount, ptr, 0x04, 0, 0)) {
                        returndatacopy(ptr, 0, returndatasize())
                        revert(ptr, returndatasize())
                    }

                    mstore(ptr, transferSelector)
                    mstore(add(ptr, 0x04), recipient)
                    mstore(add(ptr, 0x24), outputAmount)
                    if iszero(call(gas(), weth, 0, ptr, 0x44, 0, 0)) {
                        returndatacopy(ptr, 0, returndatasize())
                        revert(ptr, returndatasize())
                    }
                }
            }
        } else {
            // clipperExchange.swap(address(srcToken), address(dstToken), inputAmount, outputAmount, goodUntil, recipient, signature, _OKX_TAG);
            address clipper = address(clipperExchange);
            bytes4 selector = clipperExchange.swap.selector;
            /// @solidity memory-safe-assembly
            assembly { // solhint-disable-line no-inline-assembly
                let ptr := mload(0x40)

                mstore(ptr, selector)
                mstore(add(ptr, 0x04), srcToken)
                mstore(add(ptr, 0x24), dstToken)
                mstore(add(ptr, 0x44), inputAmount)
                mstore(add(ptr, 0x64), outputAmount)
                mstore(add(ptr, 0x84), goodUntil)
                mstore(add(ptr, 0xa4), recipient)
                mstore(add(ptr, 0xc4), add(27, shr(_SIGNATURE_V_SHIFT, vs)))
                mstore(add(ptr, 0xe4), r)
                mstore(add(ptr, 0x104), and(vs, _SIGNATURE_S_MASK))
                mstore(add(ptr, 0x124), 0x140)
                mstore(add(ptr, 0x163), _OKX_TAG_WITH_LENGTH_PREFIX)
                if iszero(call(gas(), clipper, 0, ptr, 0x169, 0, 0)) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }

        return outputAmount;
    }
}

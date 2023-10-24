// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUni.sol";

import "./libraries/UniversalERC20.sol";
import "./libraries/CommonUtils.sol";
contract UnxswapRouter is CommonUtils {
  uint256 private constant _CLAIM_TOKENS_CALL_SELECTOR_32 =
  0x0a5ea46600000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WETH_DEPOSIT_CALL_SELECTOR_32 =
  0xd0e30db000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WETH_WITHDRAW_CALL_SELECTOR_32 =
  0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _ERC20_TRANSFER_CALL_SELECTOR_32 =
  0xa9059cbb00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WETH_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
  uint256 private constant _UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
  0x0902f1ac00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 =
  0x022c0d9f00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _DENOMINATOR = 1000000000;
  uint256 private constant _NUMERATOR_OFFSET = 160;

  IERC20 private constant ETH_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------
  function _unxswapInternal(
    IERC20 srcToken,
    uint256 amount,
    uint256 minReturn,
  // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools,
    address payer,
    address receiver
  ) internal returns (uint256 returnAmount) {
    assembly {
    // solhint-disable-line no-inline-assembly
      function reRevert() {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }

      function revertWithReason(m, len) {
        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(0x40, m)
        revert(0, len)
      }

      function swap(emptyPtr, swapAmount, pair, reversed, numerator, dst) -> ret {
        mstore(emptyPtr, _UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32)
        if iszero(staticcall(gas(), pair, emptyPtr, 0x4, emptyPtr, 0x40)) {
          reRevert()
        }
        if iszero(eq(returndatasize(), 0x60)) {
          revertWithReason(0x0000001472657365727665732063616c6c206661696c65640000000000000000, 0x59) // "reserves call failed"
        }

        let reserve0 := mload(emptyPtr)
        let reserve1 := mload(add(emptyPtr, 0x20))
        if reversed {
          let tmp := reserve0
          reserve0 := reserve1
          reserve1 := tmp
        }
        ret := mul(swapAmount, numerator)
        ret := div(mul(ret, reserve1), add(ret, mul(reserve0, _DENOMINATOR)))

        mstore(emptyPtr, _UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
        switch reversed
        case 0 {
          mstore(add(emptyPtr, 0x04), 0)
          mstore(add(emptyPtr, 0x24), ret)
        }
        default {
          mstore(add(emptyPtr, 0x04), ret)
          mstore(add(emptyPtr, 0x24), 0)
        }
        mstore(add(emptyPtr, 0x44), dst)
        mstore(add(emptyPtr, 0x64), 0x80)
        mstore(add(emptyPtr, 0x84), 0)
        if iszero(call(gas(), pair, 0, emptyPtr, 0xa4, 0, 0)) {
          reRevert()
        }
      }

      let emptyPtr := mload(0x40)
      mstore(0x40, add(emptyPtr, 0xc0))

      let poolsOffset := add(calldataload(0x64), 0x4)
      let poolsEndOffset := calldataload(poolsOffset)
      poolsOffset := add(poolsOffset, 0x20)
      poolsEndOffset := add(poolsOffset, mul(0x20, poolsEndOffset))
      let rawPair := calldataload(poolsOffset)
      switch srcToken
      case 0 {
        // require callvalue() >= amount, lt: if x < y return 1，else return 0
        if eq(lt(callvalue(), amount), 1) {
          revertWithReason(0x00000011696e76616c6964206d73672e76616c75650000000000000000000000, 0x55) // "invalid msg.value"
        }

        mstore(emptyPtr, _WETH_DEPOSIT_CALL_SELECTOR_32)
        if iszero(call(gas(), _WETH, amount, emptyPtr, 0x4, 0, 0)) {
          reRevert()
        }

        mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR_32)
        mstore(add(emptyPtr, 0x4), and(rawPair, _ADDRESS_MASK))
        mstore(add(emptyPtr, 0x24), amount)
        if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
          reRevert()
        }
      }
      default {
        if callvalue() {
          revertWithReason(0x00000011696e76616c6964206d73672e76616c75650000000000000000000000, 0x55) // "invalid msg.value"
        }

        mstore(emptyPtr, _CLAIM_TOKENS_CALL_SELECTOR_32)
        mstore(add(emptyPtr, 0x4), srcToken)
        mstore(add(emptyPtr, 0x24), payer)
        mstore(add(emptyPtr, 0x44), and(rawPair, _ADDRESS_MASK))
        mstore(add(emptyPtr, 0x64), amount)
        if iszero(call(gas(), _APPROVE_PROXY, 0, emptyPtr, 0x84, 0, 0)) {
          reRevert()
        }
      }

      returnAmount := amount

      for {
        let i := add(poolsOffset, 0x20)
      } lt(i, poolsEndOffset) {
        i := add(i, 0x20)
      } {
        let nextRawPair := calldataload(i)

        returnAmount := swap(
        emptyPtr,
        returnAmount,
        and(rawPair, _ADDRESS_MASK),
        and(rawPair, _REVERSE_MASK),
        shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
        and(nextRawPair, _ADDRESS_MASK)
        )

        rawPair := nextRawPair
      }

      switch and(rawPair, _WETH_MASK)
      case 0 {
        returnAmount := swap(
        emptyPtr,
        returnAmount,
        and(rawPair, _ADDRESS_MASK),
        and(rawPair, _REVERSE_MASK),
        shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
        receiver
        )
      }
      default {
        returnAmount := swap(
        emptyPtr,
        returnAmount,
        and(rawPair, _ADDRESS_MASK),
        and(rawPair, _REVERSE_MASK),
        shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK)),
        address()
        )

        mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR_32)
        mstore(add(emptyPtr, 0x4), _WNATIVE_RELAY)
        mstore(add(emptyPtr, 0x24), returnAmount)
        if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
          reRevert()
        }

        mstore(emptyPtr, _WETH_WITHDRAW_CALL_SELECTOR_32)
        mstore(add(emptyPtr, 0x04), returnAmount)
        if iszero(call(gas(), _WNATIVE_RELAY, 0, emptyPtr, 0x24, 0, 0)) {
          reRevert()
        }

        if iszero(call(gas(), receiver, returnAmount, 0, 0, 0, 0)) {
          reRevert()
        }
      }

      if lt(returnAmount, minReturn) {
        revertWithReason(0x000000164d696e2072657475726e206e6f742072656163686564000000000000, 0x5a) // "Min return not reached"
      }
    }

    // the last pool
    bytes32 rawPair = pools[pools.length - 1];
    address pair;
    bool reserve;
    assembly {
      pair := and(rawPair, _ADDRESS_MASK)
      reserve := and(rawPair, _REVERSE_MASK)
    }
    pair = reserve ? IUni(pair).token0() : IUni(pair).token1();
    emit OrderRecord(address(srcToken), pair, tx.origin, amount, returnAmount);
    return returnAmount;
  }

  /// @notice Performs swap using Uniswap exchange. Wraps and unwraps ETH if required.
  /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
  /// @param srcToken Source token
  /// @param amountOut Exact output amount
  /// @param amountInMax Maximum allowed input amount
  /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
  // function _unxswapForExactTokensInternal(
  //   IERC20 srcToken,
  //   uint256 amountOut,
  //   uint256 amountInMax,
  // // solhint-disable-next-line no-unused-vars
  //   bytes32[] calldata pools
  // ) public payable returns (uint256 returnAmount) {
  //   uint256[] memory amountsIn = getAmountsIn(amountOut, pools);
  //   uint256 amount = amountsIn[0];
  //   require(amount <= amountInMax, "UnxswapRouter: EXCESSIVE_INPUT_AMOUNT");

  //   assembly {
  //   // solhint-disable-line no-inline-assembly
  //     function reRevert() {
  //       returndatacopy(0, 0, returndatasize())
  //       revert(0, returndatasize())
  //     }

  //     function revertWithReason(m, len) {
  //       mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
  //       mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
  //       mstore(0x40, m)
  //       revert(0, len)
  //     }

  //     function swap(emptyPtr, ret, pair, reversed, dst) {
  //       mstore(emptyPtr, _UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
  //       switch reversed
  //       case 0 {
  //         mstore(add(emptyPtr, 0x04), 0)
  //         mstore(add(emptyPtr, 0x24), ret)
  //       }
  //       default {
  //         mstore(add(emptyPtr, 0x04), ret)
  //         mstore(add(emptyPtr, 0x24), 0)
  //       }
  //       mstore(add(emptyPtr, 0x44), dst)
  //       mstore(add(emptyPtr, 0x64), 0x80)
  //       mstore(add(emptyPtr, 0x84), 0)
  //       if iszero(call(gas(), pair, 0, emptyPtr, 0xa4, 0, 0)) {
  //         reRevert()
  //       }
  //     }

  //     let emptyPtr := mload(0x40)
  //     mstore(0x40, add(emptyPtr, 0xc0))

  //     let poolsOffset := add(calldataload(0x64), 0x4)
  //     let poolsEndOffset := calldataload(poolsOffset)
  //     poolsOffset := add(poolsOffset, 0x20)
  //     poolsEndOffset := add(poolsOffset, mul(0x20, poolsEndOffset))
  //     let rawPair := calldataload(poolsOffset)
  //     switch srcToken
  //     case 0 {
  //       if iszero(eq(amountInMax, callvalue())) {
  //         revertWithReason(0x00000011696e76616c6964206d73672e76616c75650000000000000000000000, 0x55) // "invalid msg.value"
  //       }

  //       mstore(emptyPtr, _WETH_DEPOSIT_CALL_SELECTOR_32)
  //       if iszero(call(gas(), _WETH, amount, emptyPtr, 0x4, 0, 0)) {
  //         reRevert()
  //       }

  //       mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR_32)
  //       mstore(add(emptyPtr, 0x4), and(rawPair, _ADDRESS_MASK))
  //       mstore(add(emptyPtr, 0x24), amount)
  //       if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
  //         reRevert()
  //       }
  //     }
  //     default {
  //       if callvalue() {
  //         revertWithReason(0x00000011696e76616c6964206d73672e76616c75650000000000000000000000, 0x55) // "invalid msg.value"
  //       }

  //       mstore(emptyPtr, _CLAIM_TOKENS_CALL_SELECTOR_32)
  //       mstore(add(emptyPtr, 0x4), srcToken)
  //       mstore(add(emptyPtr, 0x24), caller())
  //       mstore(add(emptyPtr, 0x44), and(rawPair, _ADDRESS_MASK))
  //       mstore(add(emptyPtr, 0x64), amount)
  //       if iszero(call(gas(), _APPROVE_PROXY, 0, emptyPtr, 0x84, 0, 0)) {
  //         reRevert()
  //       }
  //     }

  //     returnAmount := amountOut
  //     let inData := add(amountsIn, 0x20)
  //     for {
  //       let i := add(poolsOffset, 0x20)
  //     } lt(i, poolsEndOffset) {
  //       i := add(i, 0x20)
  //     } {
  //       let nextRawPair := calldataload(i)
  //       inData := add(inData, 0x20)

  //       swap(
  //       emptyPtr,
  //       mload(inData),
  //       and(rawPair, _ADDRESS_MASK),
  //       and(rawPair, _REVERSE_MASK),
  //       and(nextRawPair, _ADDRESS_MASK)
  //       )
  //       rawPair := nextRawPair
  //     }

  //     switch and(rawPair, _WETH_MASK)
  //     case 0 {
  //       swap(
  //       emptyPtr,
  //       returnAmount,
  //       and(rawPair, _ADDRESS_MASK),
  //       and(rawPair, _REVERSE_MASK),
  //       caller()
  //       )
  //     }
  //     default {
  //       swap(
  //       emptyPtr,
  //       returnAmount,
  //       and(rawPair, _ADDRESS_MASK),
  //       and(rawPair, _REVERSE_MASK),
  //       address()
  //       )

  //       mstore(emptyPtr, _ERC20_TRANSFER_CALL_SELECTOR_32)
  //       mstore(add(emptyPtr, 0x4), _WNATIVE_RELAY)
  //       mstore(add(emptyPtr, 0x24), returnAmount)
  //       if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
  //         reRevert()
  //       }

  //       mstore(emptyPtr, _WETH_WITHDRAW_CALL_SELECTOR_32)
  //       mstore(add(emptyPtr, 0x04), returnAmount)
  //       if iszero(call(gas(), _WNATIVE_RELAY, 0, emptyPtr, 0x24, 0, 0)) {
  //         reRevert()
  //       }

  //       if iszero(call(gas(), caller(), returnAmount, 0, 0, 0, 0)) {
  //         reRevert()
  //       }
  //     }
  //   }

  //   // excess refund
  //   if (srcToken == ETH_ADDRESS) {
  //     uint256 ethBal = address(this).balance;
  //     if (ethBal > 0) {
  //       payable(msg.sender).transfer(ethBal);
  //     }
  //   }

  //   // the last pool
  //   bytes32 rawPair = pools[pools.length - 1];
  //   address pair;
  //   bool reserve;
  //   assembly {
  //     pair := and(rawPair, _ADDRESS_MASK)
  //     reserve := and(rawPair, _REVERSE_MASK)
  //   }
  //   pair = reserve ? IUni(pair).token0() : IUni(pair).token1();
  //   emit OrderRecord(address(srcToken), pair, tx.origin, amount, returnAmount);
  // }

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------

  // function getAmountsIn(
  //   uint256 amountOut,
  //   bytes32[] calldata pools)
  // internal view returns (uint256[] memory amounts) {
  //   amounts = new uint256[](pools.length + 1);
  //   amounts[amounts.length - 1] = amountOut;
  //   for (uint256 i = pools.length; i > 0; i--) {
  //     bytes32 rawPair = pools[i - 1];
  //     address pair;
  //     bool reserve;
  //     uint256 rate;
  //     assembly {
  //       pair := and(rawPair, _ADDRESS_MASK)
  //       reserve := and(rawPair, _REVERSE_MASK)
  //       rate := shr(_NUMERATOR_OFFSET, and(rawPair, _NUMERATOR_MASK))
  //     }
  //     (uint112 reserve0, uint112 reserve1, ) = IUni(pair).getReserves();
  //     (reserve0, reserve1) = reserve ? (reserve1, reserve0) : (reserve0, reserve1);
  //     uint256 numerator = reserve0 * amounts[i] * _DENOMINATOR;
  //     uint256 denominator = (reserve1 - amounts[i]) * rate;
  //     amounts[i - 1] = (numerator / denominator) + 1;
  //   }
  // }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/UniversalERC20.sol";
import "./libraries/RevertReasonParser.sol";

import "./interfaces/IERC20Permit.sol";
import "./interfaces/IDaiLikePermit.sol";

interface IUniswapV2Pair {
  function token0() external returns (address);

  function token1() external returns (address);
}

/// @title Base contract with common payable logics
abstract contract EthReceiver {
  receive() external payable {
    // solhint-disable-next-line avoid-tx-origin
    require(msg.sender != tx.origin, "ETH deposit rejected");
  }
}

/// @title Base contract with common permit handling logics
contract Permitable {
  function _permit(address token, bytes calldata permit) internal {
    if (permit.length > 0) {
      bool success;
      bytes memory result;
      if (permit.length == 32 * 7) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
      } else if (permit.length == 32 * 8) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = token.call(abi.encodePacked(IDaiLikePermit.permit.selector, permit));
      } else {
        revert("Wrong permit length");
      }
      if (!success) {
        revert(RevertReasonParser.parse(result, "Permit failed: "));
      }
    }
  }
}

contract UnxswapRouter is EthReceiver, Permitable {
  uint256 private constant _CLAIM_TOKENS_CALL_SELECTOR_32 =
    0x0a5ea46600000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WETH_DEPOSIT_CALL_SELECTOR_32 =
    0xd0e30db000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WETH_WITHDRAW_CALL_SELECTOR_32 =
    0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _ERC20_TRANSFER_CALL_SELECTOR_32 =
    0xa9059cbb00000000000000000000000000000000000000000000000000000000;
  uint256 public constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
  uint256 public constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WETH_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
  uint256 private constant _UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 =
    0x0902f1ac00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 =
    0x022c0d9f00000000000000000000000000000000000000000000000000000000;
  uint256 private constant _DENOMINATOR = 1000000000;
  uint256 private constant _NUMERATOR_OFFSET = 160;
  /// @dev WETH address is network-specific and needs to be changed before deployment.
  /// It can not be moved to immutable as immutables are not supported in assembly
  // ETH:     C02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  // BSC:     bb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
  // OEC:     8f8526dbfd6e38e3d8307702ca8469bae6c56c15
  // LOCAL:   5FbDB2315678afecb367f032d93F642f64180aa3
  // POLYGON: 0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
  // AVAX:    B31f66AA3C1e785363F0875A1B74E27b85FD66c7
  uint256 public constant _WETH = 0x000000000000000000000000B31f66AA3C1e785363F0875A1B74E27b85FD66c7;
  // ETH:     70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58
  // BSC:     d99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98
  // OEC:     E9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF
  // LOCAL:   e7f1725E7734CE288F8367e1Bb143E90bb3F0512
  // POLYGON: 40aA958dd87FC8305b97f2BA922CDdCa374bcD7f
  // AVAX:    70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58
  uint256 public constant _APPROVE_PROXY_32 = 0x00000000000000000000000070cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
  // ETH:     5703B683c7F928b721CA95Da988d73a3299d4757
  // BSC:     0B5f474ad0e3f7ef629BD10dbf9e4a8Fd60d9A48
  // OEC:     d99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98
  // LOCAL:   D49a0e9A4CD5979aE36840f542D2d7f02C4817Be
  // POLYGON: f332761c673b59B21fF6dfa8adA44d78c12dEF09
  // AVAX:    3B86917369B83a6892f553609F3c2F439C184e31
  uint256 public constant _WNATIVE_RELAY_32 = 0x0000000000000000000000003B86917369B83a6892f553609F3c2F439C184e31;

  uint256 public constant _WEIGHT_MASK = 0x00000000000000000000ffff0000000000000000000000000000000000000000;

  // address public approveProxy;

  event OrderRecord(address fromToken, address toToken, address sender, uint256 fromAmount, uint256 returnAmount);

  /// @notice Same as `unoswap` but calls permit first,
  /// allowing to approve token spending and make a swap in one transaction.
  /// @param srcToken Source token
  /// @param amount Amount of source tokens to swap
  /// @param minReturn Minimal allowed returnAmount to make transaction commit
  /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
  /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
  /// See tests for examples
  function unxswapWithPermit(
    IERC20 srcToken,
    uint256 amount,
    uint256 minReturn,
    bytes32[] calldata pools,
    bytes calldata permit
  ) external returns (uint256 returnAmount) {
    _permit(address(srcToken), permit);
    return unxswap(srcToken, amount, minReturn, pools);
  }

  /// @notice Performs swap using Uniswap exchange. Wraps and unwraps ETH if required.
  /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
  /// @param srcToken Source token
  /// @param amount Amount of source tokens to swap
  /// @param minReturn Minimal allowed returnAmount to make transaction commit
  /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
  function unxswap(
    IERC20 srcToken,
    uint256 amount,
    uint256 minReturn,
    // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools
  ) public payable returns (uint256 returnAmount) {
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
        if iszero(eq(amount, callvalue())) {
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
        mstore(add(emptyPtr, 0x24), caller())
        mstore(add(emptyPtr, 0x44), and(rawPair, _ADDRESS_MASK))
        mstore(add(emptyPtr, 0x64), amount)
        if iszero(call(gas(), _APPROVE_PROXY_32, 0, emptyPtr, 0x84, 0, 0)) {
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
          caller()
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
        mstore(add(emptyPtr, 0x4), _WNATIVE_RELAY_32)
        mstore(add(emptyPtr, 0x24), returnAmount)
        if iszero(call(gas(), _WETH, 0, emptyPtr, 0x44, 0, 0)) {
          reRevert()
        }

        mstore(emptyPtr, _WETH_WITHDRAW_CALL_SELECTOR_32)
        mstore(add(emptyPtr, 0x04), returnAmount)
        if iszero(call(gas(), _WNATIVE_RELAY_32, 0, emptyPtr, 0x24, 0, 0)) {
          reRevert()
        }

        if iszero(call(gas(), caller(), returnAmount, 0, 0, 0, 0)) {
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
    pair = reserve ? IUniswapV2Pair(pair).token0() : IUniswapV2Pair(pair).token1();
    emit OrderRecord(address(srcToken), pair, msg.sender, amount, minReturn);
  }
}

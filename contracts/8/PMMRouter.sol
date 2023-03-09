// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/SafeERC20.sol";
import "./libraries/UniversalERC20.sol";

import "./libraries/ECDSA.sol";
import "./libraries/draft-EIP712Upgradable.sol";
import "./interfaces/IApproveProxy.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniV3.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWNativeRelayer.sol";
import "./libraries/CommonUtils.sol";
import "./libraries/PMMLib.sol";
import "./PMMRouterStorage.sol";

/// @title PMMRouter
/// @notice Private Market Maker Router for order book
abstract contract PMMRouter is CommonUtils, EIP712Upgradable, PMMRouterStorage {
  using SafeERC20 for IERC20;
  using UniversalERC20 for IERC20;

  // _ORDER_TYPEHASH = keccak256("PMMSwapRequest(uint256 pathIndex,address payer,address fromToken,address toToken,uint256 fromTokenAmountMax,uint256 toTokenAmountMax,uint256 salt,uint256 deadLine,bool isPushOrder,bytes extension)")
  bytes32 private constant _ORDER_TYPEHASH = 0x5d068ce469dcf41137bcb6c3e1894e076ad915392f28fda19ba41601d33c32a6;
  bytes32 private constant _NUM_MASK = 0xffff000000000000000000000000000000000000000000000000000000000000;
  string private constant _NAME = "METAX MARKET MAKER";
  string private constant _VERSION = "1.0"; 
  uint256 private constant _ORDER_FINALIZED = 0x8000000000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _MAX_FEE_RATE = 10000;
  address private constant _FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;  //ETH
  // address private constant _FACTORY = 0xF45B1CdbA9AACE2e9bbE80bf376CE816bb7E73FB;  //hardhat

  // ============ Event ============
  event PMMFeeConfigChanged(address indexed _sender, uint256 _feeRateAndReceiver);
  event OperatorChanged(address indexed payer, address operator);
  event QuotesCancelled(address indexed ender, PMMLib.PMMSwapRequest[] orders, uint256[] remainings);
  event PriceProtected(uint256 amount, uint256 protectedAmount);

  // ============ Error ============
  error SwapExpired();
  error InvaldFeeRate();
  error InvalidFeeReceiver();
  error OrderFinalizedAlready();
  error InvalidCanceller();
  error InvalidFromAmount();
  error InvalidToToken();
  error MinReturnNotReached();


  function _initializePMMRouter(
    uint256 _feeRateAndReceiver
  ) internal {
    _setPMMFeeConfig(_feeRateAndReceiver);
  }

  // ============ OnlyOwner ============
  function _setPMMFeeConfig(uint256 _feeRateAndReceiver) internal {
    (uint256 _feeRate, address _feeReceiver) = decodeNumAndAddress(_feeRateAndReceiver);
    if(_feeRate > _MAX_FEE_RATE) { revert InvaldFeeRate();}
    if(_feeReceiver == address(0)) { revert InvalidFeeReceiver();} 
    feeRateAndReceiver = _feeRateAndReceiver;
    emit PMMFeeConfigChanged(msg.sender, _feeRateAndReceiver);
  }

  // ============ External ============
  function setOperator(address _operator) external {
    operator[msg.sender] = _operator;
    emit OperatorChanged(msg.sender, _operator);
  }

  function cancelQuotes(PMMLib.PMMSwapRequest[] calldata orders) external{
    uint256 len = orders.length;
    uint256[] memory remainings = new uint256[](len);
    for(uint256 i = 0; i < len;) {
      if(msg.sender != operator[orders[i].payer] && msg.sender != orders[i].payer) {revert InvalidCanceller();} 
      bytes32 orderHash = _hashTypedDataV4(hashOrder(orders[i]));
      remainings[i] = orderRemaining[orderHash];
      if(remainings[i] == _ORDER_FINALIZED) {revert OrderFinalizedAlready();}
      orderRemaining[orderHash] = _ORDER_FINALIZED;
      unchecked { ++i; }
    } 
    emit QuotesCancelled(msg.sender, orders, remainings);
  }

  function _PMMV2Swap(
    address fromTokenPayer,
    address receiver,
    PMMLib.PMMBaseRequest memory baseRequest,
    PMMLib.PMMSwapRequest calldata request
  ) internal returns (uint256 returnAmount) {
    if(baseRequest.fromTokenAmount == 0) {revert InvalidFromAmount();}
    if(baseRequest.fromNative && baseRequest.fromTokenAmount != msg.value && request.fromToken != _WETH) {revert InvalidFromAmount();}
    if(baseRequest.toNative && request.toToken != _WETH) {revert InvalidToToken();}
    if(baseRequest.deadLine < block.timestamp) {revert SwapExpired();}

    returnAmount = baseRequest.toNative ? receiver.balance : IERC20(request.toToken).balanceOf(receiver);
    uint256 errorCode = _pmmSwapInternal(baseRequest.fromTokenAmount, fromTokenPayer, receiver, request, baseRequest.fromNative, baseRequest.toNative);
    if (errorCode > 0) {
      revert PMMLib.PMMErrorCode(errorCode);
    }
    returnAmount = baseRequest.toNative ? receiver.balance - returnAmount : IERC20(request.toToken).balanceOf(receiver) - returnAmount;
    if(returnAmount < baseRequest.minReturnAmount) {revert MinReturnNotReached();}

    emit OrderRecord(request.fromToken, request.toToken, request.payer, baseRequest.fromTokenAmount, returnAmount);
    return returnAmount;
  }

  function _pmmSwapInternal(
    uint256 actualAmountRequest,
    address fromTokenPayer,
    address receiver,
    PMMLib.PMMSwapRequest calldata request,
    bool fromNative,
    bool toNative
  ) internal returns (uint256 errorCode){

    // check order deadline
    if (request.deadLine < block.timestamp) {return uint256(PMMLib.PMM_ERROR.QUOTE_EXPIRED);}

    // get transfer amount of toToken
    uint256 amount = (actualAmountRequest * request.toTokenAmountMax) / request.fromTokenAmountMax;
    uint256 source;
    assembly{
      source := calldataload(add(request,0x220))
    }
    uint256 protectedAmount = _getProtectedAmount(actualAmountRequest, source, request.fromToken, request.toToken);
    if (amount > protectedAmount) {
      amount = protectedAmount;
      emit PriceProtected(amount, protectedAmount);
    }

    bytes32 orderHash = _hashTypedDataV4(hashOrder(request));
    errorCode = validateSigBatch(orderHash, request.payer, request.extension);
    if (errorCode > 0) {
      return errorCode;
    }

    errorCode = updateOrder(amount, orderHash, request.toTokenAmountMax);
   if (errorCode > 0) {
      return errorCode;
    }

    // avoid stack too deep
    // TODO: feeRate is zero now, so try to save gas
    // {
    //   (uint256 feeRate, address feeReceiver) = decodeNumAndAddress(feeRateAndReceiver);
    //   if(feeRate > 0) {
    //     uint256 fee = (amount * feeRate) / 1000000;
    //     amount -= fee;
    //     IApproveProxy(_APPROVE_PROXY).claimTokens(request.toToken, request.payer, feeReceiver, fee);
    //   }
    // }

    // Maker -> Taker
    if (toNative) {
      IApproveProxy(_APPROVE_PROXY).claimTokens(request.toToken, request.payer, _WNATIVE_RELAY, amount);
      IWNativeRelayer(_WNATIVE_RELAY).withdraw(amount);
      payable(receiver).transfer(amount);
    } else {
      IApproveProxy(_APPROVE_PROXY).claimTokens(request.toToken, request.payer, receiver, amount);
    }

    // Taker -> Maker
    if (fromNative) {
      IWETH(_WETH).deposit{ value: actualAmountRequest }();
      IERC20(_WETH).safeTransfer(request.payer, actualAmountRequest);
    } else if(fromTokenPayer == address(this)) {
      IERC20(request.fromToken).safeTransfer(request.payer, actualAmountRequest);
    } else {
      IApproveProxy(_APPROVE_PROXY).claimTokens(request.fromToken, fromTokenPayer, request.payer, actualAmountRequest);
    }

  }

  // ============ Internal ============
  function validateSigBatch(
    bytes32 digest,
    address payer,
    bytes memory extension    
  ) internal view returns (uint256 errorCode) {
    bytes32 operatorSigR;
    bytes32 operatorSigVs;

    assembly{
      operatorSigR := mload(add(extension, 0x60))
      operatorSigVs := mload(add(extension, 0x80))
    }

    if (!validateOperatorSig(payer, ECDSA.recover(digest, operatorSigR, operatorSigVs))) {
      return uint256(PMMLib.PMM_ERROR.INVALID_OPERATOR);
    }

    return uint256(PMMLib.PMM_ERROR.NO_ERROR);

  }

  function validateOperatorSig(address payer, address operatorAddress) internal view returns (bool) {
    if (operatorAddress == payer || operatorAddress == operator[payer]) {
      return true;
    }
    return false;
  }

  function updateOrder(uint256 amount, bytes32 orderHash, uint256 toTokenAmountMax) internal returns (uint256 errorCode) {
    uint256 remaining = orderRemaining[orderHash];
    // in case of canceled or finalized order
    if (remaining == _ORDER_FINALIZED) {
      return uint256(PMMLib.PMM_ERROR.ORDER_CANCELLED_OR_FINALIZED);
    }

    if (remaining == 0 && toTokenAmountMax > 0) {
      remaining = toTokenAmountMax;
    }
    if (amount > remaining) {
      return uint256(PMMLib.PMM_ERROR.REMAINING_AMOUNT_NOT_ENOUGH);
    } else if (amount == remaining) {
      orderRemaining[orderHash] = _ORDER_FINALIZED;
    } else {
      orderRemaining[orderHash] = remaining - amount;
    }
    return uint256(PMMLib.PMM_ERROR.NO_ERROR);
  }

  // =============== price protection ===============
  function _getProtectedAmount(uint256 fromTokenAmount, uint256 source, address fromToken, address toToken) internal view returns (uint256 protectedAmount) {
    (uint256 reverse, address pair) = decodeNumAndAddress(source);
    if (pair == address(0)) {
      pair = IUniswapV2Factory(_FACTORY).getPair(fromToken, toToken);
      address token0 = IUniswapV2Pair(pair).token0();
      if (token0 == toToken) {reverse = 1;}
    }
    (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
    if (reserve0 == 0 || reserve1 == 0) {return type(uint256).max;}
    if (reverse == 1) {
      protectedAmount = fromTokenAmount * uint256(reserve0) / uint256(reserve1);
    } else {
      protectedAmount = fromTokenAmount * uint256(reserve1) / uint256(reserve0);
    }
  }

  function decodeNumAndAddress(uint256 _numAndAddress) internal pure returns (uint256 num, address account) {
    assembly {
      num := shr(240, and(_numAndAddress, _NUM_MASK))
      account := and(_numAndAddress, _ADDRESS_MASK)
    }
  }

  /// @dev Get the struct hash of a PMMSwapRequest.
  /// @param order The SwapRequest.
  /// @return structHash The struct hash of the order.
  function hashOrder(PMMLib.PMMSwapRequest calldata order) internal pure returns (bytes32 structHash) {
    assembly {
      let mem := mload(0x40)
      mstore(mem, _ORDER_TYPEHASH)
      calldatacopy(add(mem, 0x20), order, 0x120)
      structHash := keccak256(mem, 0x140)
    }
  }

}

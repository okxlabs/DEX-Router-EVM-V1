// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./TokenApproveProxy.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IApproveProxy.sol";
import "./interfaces/IMarketMaker.sol";
import "./interfaces/IWNativeRelayer.sol";

import "./libraries/UniversalERC20.sol";
import "./libraries/CommonUtils.sol";
import "./libraries/Permitable.sol";
import "./libraries/EthReceiver.sol";
import "./libraries/PMMLib.sol";

/// @title SmartRouter
/// @notice Router of smart swap
/// @dev Router of smart swap
contract SmartRouter is ReentrancyGuardUpgradeable, CommonUtils, Permitable, EthReceiver {
  using UniversalERC20 for IERC20;

  bytes32 private constant _PMM_FLAG8_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
  bytes32 private constant _PMM_FLAG4_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
  bytes32 private constant _PMM_INDEX_I_MASK = 0x00ff000000000000000000000000000000000000000000000000000000000000;
  bytes32 private constant _PMM_INDEX_J_MASK = 0x0000ff0000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _WEIGHT_MASK = 0x00000000000000000000ffff0000000000000000000000000000000000000000;

  address public immutable dexRouter;

  struct BaseRequest {
    uint256 fromToken;
    address toToken;
    uint256 fromTokenAmount;
    uint256 minReturnAmount;
    uint256 deadLine;
  }

  struct RouterPath {
    address[] mixAdapters;
    address[] assetTo;
    uint256[] rawData;
    bytes[] extraData;
    uint256 fromToken;
  }

  //-------------------------------
  //------- Modifier --------------
  //-------------------------------

  modifier isExpired(uint256 deadLine) {
    require(deadLine >= block.timestamp, "Route: expired");
    _;
  }

  modifier onlyDexRouter() {
    require(msg.sender == dexRouter, "only DexRouter");
    _;
  }

  constructor(address _dexRouter) {
    dexRouter = _dexRouter;
  }

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------

  function _exeForks(address payer, uint256 batchAmount, RouterPath memory path, bool isNotFirst) internal {
    address fromToken = bytes32ToAddress(path.fromToken);

    // execute multiple Adapters for a transaction pair
    uint256 pathLength = path.mixAdapters.length;
    for (uint256 i = 0; i < pathLength; ) {
      bytes32 rawData = bytes32(path.rawData[i]);
      address poolAddress;
      bool reserves;
      uint256 weight;
      assembly {
        poolAddress := and(rawData, _ADDRESS_MASK)
        reserves := and(rawData, _REVERSE_MASK)
        weight := shr(160, and(rawData, _WEIGHT_MASK))
      }
      require(weight >= 0 && weight <= 10000, "weight out of range");
      uint256 _fromTokenAmount = (batchAmount * weight) / 10000;

      _transferInternal(payer, path.assetTo[i], fromToken, _fromTokenAmount, isNotFirst);

      if (reserves) {
        IAdapter(path.mixAdapters[i]).sellQuote(address(this), poolAddress, path.extraData[i]);
      } else {
        IAdapter(path.mixAdapters[i]).sellBase(address(this), poolAddress, path.extraData[i]);
      }
      unchecked {
        ++i;
      }
    }
  }

  function _exeHop(
    address payer,
    uint256 batchAmount,
    uint256 forceInternalTransferFrom,
    RouterPath[] calldata hops,
    PMMLib.PMMSwapRequest[] memory extraData
  ) internal {
    address fromToken;
    uint8 pmmIndex;

    // try to replace this batch by pmm
    if (isReplace(hops[0].fromToken)) {
      fromToken = bytes32ToAddress(hops[0].fromToken);
      pmmIndex = getPmmIIndex(hops[0].fromToken);
      if (_tryPmmSwap(payer, fromToken, batchAmount, extraData[pmmIndex], false) == 0) {
        return;
      }
    }

    // excute hop
    // hop and fork are the same flag bit
    uint256 hopLength = hops.length;
    for (uint256 i = 0; i < hopLength; ++i) {
      if (i > 0) {
        fromToken = bytes32ToAddress(hops[i].fromToken);
        batchAmount = IERC20(fromToken).universalBalanceOf(address(this));
      }

      // 3.1 try to replace this hop by pmm
      if (isHopReplace(hops[i].fromToken)) {
        fromToken = bytes32ToAddress(hops[i].fromToken);
        pmmIndex = getPmmJIndex(hops[i].fromToken);
        if (_tryPmmSwap(payer, fromToken, batchAmount, extraData[pmmIndex], i > 0) == 0) {
          continue;
        }
      }
      if(forceInternalTransferFrom == 1){
        // 3.2 execute forks
        _exeForks(payer, batchAmount, hops[i], true);
      }else{
        // 3.2 execute forks
        _exeForks(payer, batchAmount, hops[i], i > 0);
      }
    }
  }

  function _transferInternal(
    address payer,
    address to,
    address token,
    uint256 amount,
    bool isTransfer
  ) private {
    if (isTransfer || token == _WETH) {
      SafeERC20.safeTransfer(IERC20(token), to, amount);
    } else {
      IApproveProxy(_APPROVE_PROXY).claimTokens(token, payer, to, amount);
    }
  }

  function _transferTokenToUser(address token, address to) internal {
    if ((IERC20(token).isETH())) {
      uint256 wethBal = IERC20(_WETH).balanceOf(address(this));
      if (wethBal > 0) {
        IWETH(_WETH).transfer(_WNATIVE_RELAY, wethBal);
        IWNativeRelayer(_WNATIVE_RELAY).withdraw(wethBal);
      }
      uint256 ethBal = address(this).balance;
      if (ethBal > 0) {
        payable(to).transfer(ethBal);
      }
    } else {
      uint256 bal = IERC20(token).balanceOf(address(this));
      if (bal > 0) {
        SafeERC20.safeTransfer(IERC20(token), to, bal);
      }
    }
  }

  function _tryPmmSwap(
    address payer,
    address fromToken,
    uint256 actualRequest,
    PMMLib.PMMSwapRequest memory pmmRequest,
    bool isNotFirst
  ) internal returns (uint256 errorCode) {
    uint256 subIndex;
    bytes memory extension = pmmRequest.extension;
    if (UniversalERC20.isETH(IERC20(fromToken))) {
      // market makers will get WETH
      fromToken = _WETH;
    }
    assembly{
      subIndex := mload(add(extension, 0x40))
    }
    // check from token
    if (pmmRequest.fromToken != fromToken) {revert PMMLib.PMMErrorCode(uint256(PMMLib.PMM_ERROR.WRONG_FROM_TOKEN));}

    if (isNotFirst || fromToken == _WETH) {
      payer = address(this);
    }

    // settle funds in MarketMaker, send funds to pmmAdapter
    uint256 toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this));
    address tokenApprove = IApproveProxy(_APPROVE_PROXY).tokenApprove();
    SafeERC20.forceApprove(IERC20(pmmRequest.fromToken), tokenApprove, actualRequest);
    errorCode = IMarketMaker(dexRouter).PMMV2SwapFromSmartRouter(actualRequest, payer, pmmRequest);

    SafeERC20.forceApprove(IERC20(pmmRequest.fromToken), tokenApprove, 0);
    toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this)) - toTokenAmount;

    emit PMMLib.PMMSwap (
      pmmRequest.pathIndex,
      subIndex,
      pmmRequest.payer,
      fromToken,
      pmmRequest.toToken,
      actualRequest,
      toTokenAmount,
      errorCode
    );
    return errorCode;
  }

  function bytes32ToAddress(uint256 param) internal pure returns (address result) {
    assembly {
      result := and(param, _ADDRESS_MASK)
    }
  }

  function isReplace(uint256 token) internal pure returns (bool result) {
    assembly {
      result := and(token, _PMM_FLAG8_MASK)
    }
  }

  function isHopReplace(uint256 token) internal pure returns (bool result) {
    assembly {
      result := and(token, _PMM_FLAG4_MASK)
    }
  }

  function getPmmIIndex(uint256 token) internal pure returns (uint8 result) {
    assembly {
      result := shr(240, and(token, _PMM_INDEX_I_MASK))
    }
  }

  function getPmmJIndex(uint256 token) internal pure returns (uint8 result) {
    assembly {
      result := shr(232, and(token, _PMM_INDEX_J_MASK))
    }
  }

  function smartSwap(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData,
    address payer,
    address receiver
  ) public payable isExpired(baseRequest.deadLine) nonReentrant onlyDexRouter returns (uint256 returnAmount) {
    // 1. transfer from token in
    BaseRequest memory localBaseRequest = baseRequest;
    require(localBaseRequest.fromTokenAmount > 0, "Route: fromTokenAmount must be > 0");
    address baseRequestFromToken = bytes32ToAddress(localBaseRequest.fromToken);
    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver);

    // In order to deal with ETH/WETH transfer rules in a unified manner, 
    // we do not need to judge according to fromToken.
    if (UniversalERC20.isETH(IERC20(baseRequestFromToken))) {
      IWETH(_WETH).deposit{ value: localBaseRequest.fromTokenAmount }();
    } else if (baseRequestFromToken == _WETH) {
      IApproveProxy(_APPROVE_PROXY).claimTokens(
        baseRequestFromToken,
        payer,
        address(this),
        localBaseRequest.fromTokenAmount
      );
    }

    // 2. check total batch amount
    {
      // avoid stack too deep
      uint256 totalBatchAmount;
      for (uint256 i = 0; i < batchesAmount.length; ) {
        totalBatchAmount += batchesAmount[i];
        unchecked {
          ++i;
        }
      }
      require(
        totalBatchAmount <= localBaseRequest.fromTokenAmount,
        "Route: number of batches should be <= fromTokenAmount"
      );
    }

    // 3. try to replace the whole swap by pmm
    uint256 errorCode;
    if (isReplace(localBaseRequest.fromToken)) {
      uint8 pmmIndex = getPmmIIndex(localBaseRequest.fromToken);
      errorCode = _tryPmmSwap(payer, baseRequestFromToken, localBaseRequest.fromTokenAmount, extraData[pmmIndex], false);
      if ( errorCode == 0) {
        _transferTokenToUser(localBaseRequest.toToken, receiver);
        returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
        require(returnAmount >= localBaseRequest.minReturnAmount, "Route: Return amount is not enough");
        emit OrderRecord(baseRequestFromToken, localBaseRequest.toToken, tx.origin, localBaseRequest.fromTokenAmount, returnAmount);
        return returnAmount;
      }
    }

    if (batches.length == 0 || batches[0].length == 0) {
      revert PMMLib.PMMErrorCode(errorCode);
    }

    // 4. execute batch
    for (uint256 i = 0; i < batches.length; ) {
      // execute hop, if the whole swap replacing by pmm fails, the funds will return to dexRouter	
      _exeHop(payer, batchesAmount[i], 0, batches[i], extraData);
      unchecked {
        ++i;
      }
    }

    // 5. transfer tokens to user
    _transferTokenToUser(baseRequestFromToken, receiver);
    _transferTokenToUser(localBaseRequest.toToken, receiver);

    // 6. check minReturnAmount
    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
    require(returnAmount >= localBaseRequest.minReturnAmount, "Min return not reached");

    emit OrderRecord(baseRequestFromToken, localBaseRequest.toToken, tx.origin, localBaseRequest.fromTokenAmount, returnAmount);
    return returnAmount;
  }

  struct SwapInvest{
    address baseRequestFromToken;
    uint256 actualFromTokenAmount;
    uint256 errorCode;
  }

  function _smartSwapInvestInternal(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData,
    address payer,
    address receiver
  ) internal returns (uint256 returnAmount) {
    // avoid stack too deep
    SwapInvest memory vars;
    // 1. token has been transferred in
    BaseRequest memory localBaseRequest = baseRequest;
    require(localBaseRequest.fromTokenAmount > 0, "Route: fromTokenAmount must be > 0");
    vars.baseRequestFromToken = bytes32ToAddress(localBaseRequest.fromToken);
    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver);

    vars.actualFromTokenAmount = IERC20(vars.baseRequestFromToken).universalBalanceOf(address(this));
    require(vars.actualFromTokenAmount > 0, "Route: actualFromTokenAmount must be > 0");

    localBaseRequest.minReturnAmount = localBaseRequest.minReturnAmount * vars.actualFromTokenAmount / localBaseRequest.fromTokenAmount;
    
    if (UniversalERC20.isETH(IERC20(vars.baseRequestFromToken))) {
      IWETH(_WETH).deposit{ value: vars.actualFromTokenAmount }();
    }

    // 2. check total batch amount
    {
      // avoid stack too deep
      uint256 totalBatchAmount;
      for (uint256 i = 0; i < batchesAmount.length; ) {
        totalBatchAmount += batchesAmount[i];
        unchecked {
          ++i;
        }
      }
      require(
        totalBatchAmount <= localBaseRequest.fromTokenAmount,
        "Route: number of batches should be <= fromTokenAmount"
      );
    }

    // 3. try to replace the whole swap by pmm
    if (isReplace(localBaseRequest.fromToken)) {
      uint8 pmmIndex = getPmmIIndex(localBaseRequest.fromToken);
      vars.errorCode = _tryPmmSwap(payer, vars.baseRequestFromToken, vars.actualFromTokenAmount, extraData[pmmIndex], false);
      if ( vars.errorCode == 0) {
        _transferTokenToUser(localBaseRequest.toToken, receiver);
        returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
        require(returnAmount >= localBaseRequest.minReturnAmount, "Route: Return amount is not enough");
        emit OrderRecord(vars.baseRequestFromToken, localBaseRequest.toToken, tx.origin, vars.actualFromTokenAmount, returnAmount);
        return returnAmount;
      }
    }

    if (batches.length == 0 || batches[0].length == 0) {
      revert PMMLib.PMMErrorCode(vars.errorCode);
    }
    // 4. execute batch
    for (uint256 i = 0; i < batches.length; ) {
      // execute hop, if the whole swap replacing by pmm fails, the funds will return to dexRouter
      _exeHop(payer, batchesAmount[i] * vars.actualFromTokenAmount / localBaseRequest.fromTokenAmount, 1, batches[i], extraData);
      unchecked {
        ++i;
      }
    }

    // 5. transfer tokens to user
    _transferTokenToUser(vars.baseRequestFromToken, tx.origin);
    _transferTokenToUser(localBaseRequest.toToken, receiver);

    // 6. check minReturnAmount
    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
    require(returnAmount >= localBaseRequest.minReturnAmount, "Min return not reached");

    emit OrderRecord(vars.baseRequestFromToken, localBaseRequest.toToken, tx.origin, vars.actualFromTokenAmount, returnAmount);
    return returnAmount;
  }

  function smartSwapByInvest(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData,
    address to
  ) public payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    returnAmount = _smartSwapInvestInternal(baseRequest, batchesAmount, batches, extraData, address(this), to);
  }

}
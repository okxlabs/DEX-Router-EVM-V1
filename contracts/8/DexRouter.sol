// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./TokenApproveProxy.sol";
import "./UnxswapRouter.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IAdapterWithResult.sol";
import "./interfaces/IApproveProxy.sol";
import "./interfaces/IMarketMaker.sol";
import "./interfaces/IWNativeRelayer.sol";

/// @title DexRouter
/// @notice Entrance of Split trading in Dex platform
/// @dev Entrance of Split trading in Dex platform
contract DexRouter is UnxswapRouter, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using UniversalERC20 for IERC20;

  address public approveProxy;
  bytes32 public constant _PMM_FLAG8_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
  bytes32 public constant _PMM_FLAG4_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
  bytes32 public constant _PMM_INDEX_I_MASK = 0x00ff000000000000000000000000000000000000000000000000000000000000;
  bytes32 public constant _PMM_INDEX_J_MASK = 0x0000ff0000000000000000000000000000000000000000000000000000000000;

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

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  //-------------------------------
  //------- Events ----------------
  //-------------------------------

  event ApproveProxyChanged(address approveProxy);
  event PMMSwap(
    uint256 pathIndex,
    uint256 subIndex,
    address payer,
    address fromToken,
    address toToken,
    uint256 fromAmount,
    uint256 toAmount,
    uint256 errorCode
  );

  //-------------------------------
  //------- Modifier --------------
  //-------------------------------

  modifier isExpired(uint256 deadLine) {
    require(deadLine >= block.timestamp, "Route: expired");
    _;
  }

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------

  function _exeForks(uint256 batchAmount, RouterPath memory path) internal {
    address fromToken = bytes32ToAddress(path.fromToken);

    // execute multiple Adapters for a transaction pair
    for (uint256 i = 0; i < path.mixAdapters.length; i++) {
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
      address tokenApprove = IApproveProxy(approveProxy).tokenApprove();
      SafeERC20.safeApprove(IERC20(fromToken), tokenApprove, _fromTokenAmount);
      // send the asset to the adapter
      _deposit(address(this), path.assetTo[i], fromToken, _fromTokenAmount);
      if (reserves) {
        IAdapter(path.mixAdapters[i]).sellQuote(address(this), poolAddress, path.extraData[i]);
      } else {
        IAdapter(path.mixAdapters[i]).sellBase(address(this), poolAddress, path.extraData[i]);
      }
      SafeERC20.safeApprove(IERC20(fromToken), tokenApprove, 0);
    }
  }

  function _exeHop(
    uint256 batchAmount,
    RouterPath[] calldata hops,
    IMarketMaker.PMMSwapRequest[] memory extraData
  ) internal {
    address fromToken;
    uint8 pmmIndex;

    // try to replace this batch by pmm
    if (isReplace(hops[0].fromToken)) {
      fromToken = bytes32ToAddress(hops[0].fromToken);
      pmmIndex = getPmmIIndex(hops[0].fromToken);
      if (_tryPmmSwap(fromToken, batchAmount, extraData[pmmIndex]) == 0) {
        return;
      }
    }

    // excute hop
    for (uint256 i = 0; i < hops.length; i++) {
      if (i > 0) {
        fromToken = bytes32ToAddress(hops[i].fromToken);
        batchAmount = IERC20(fromToken).universalBalanceOf(address(this));
      }

      // 3.1 try to replace this hop by pmm
      if (isHopReplace(hops[i].fromToken)) {
        fromToken = bytes32ToAddress(hops[i].fromToken);
        pmmIndex = getPmmJIndex(hops[i].fromToken);
        if (_tryPmmSwap(fromToken, batchAmount, extraData[pmmIndex]) == 0) {
          continue;
        }
      }

      // 3.2 execute forks
      _exeForks(batchAmount, hops[i]);
    }
  }

  function _deposit(
    address from,
    address to,
    address token,
    uint256 amount
  ) internal {
    if (UniversalERC20.isETH(IERC20(token))) {
      if (amount > 0) {
        IWETH(address(uint160(_WETH))).deposit{ value: amount }();
        if (to != address(this)) {
          SafeERC20.safeTransfer(IERC20(address(uint160(_WETH))), to, amount);
        }
      }
    } else {
      IApproveProxy(approveProxy).claimTokens(token, from, to, amount);
    }
  }

  function _transferTokenToUser(address token) internal {
    if ((IERC20(token).isETH())) {
      uint256 wethBal = IERC20(address(uint160(_WETH))).balanceOf(address(this));
      if (wethBal > 0) {
        IWETH(address(uint160(_WETH))).transfer(address(uint160(_WNATIVE_RELAY_32)), wethBal);
        IWNativeRelayer(address(uint160(_WNATIVE_RELAY_32))).withdraw(wethBal);
      }
      uint256 ethBal = address(this).balance;
      if (ethBal > 0) {
        payable(msg.sender).transfer(ethBal);
      }
    } else {
      uint256 bal = IERC20(token).balanceOf(address(this));
      if (bal > 0) {
        SafeERC20.safeTransfer(IERC20(token), msg.sender, bal);
      }
    }
  }

  function _tryPmmSwap(
    address fromToken,
    uint256 actualRequest,
    IMarketMaker.PMMSwapRequest memory pmmRequest
  ) internal returns (uint256 errorCode) {
    address pmmAdapter;
    uint256 subIndex;
    bytes memory extension = pmmRequest.extension;
    assembly{
      pmmAdapter := mload(add(extension, 0x20))
      subIndex := mload(add(extension, 0x40))
    }
    // check from token
    if (pmmRequest.fromToken != fromToken) {
      errorCode = uint256(IMarketMaker.PMM_ERROR.WRONG_FROM_TOKEN);
      emit PMMSwap (
        pmmRequest.pathIndex, 
        subIndex, 
        pmmRequest.payer, 
        fromToken, 
        pmmRequest.toToken, 
        actualRequest, 
        0, 
        errorCode
      );
      return errorCode;
    }

    if (pmmRequest.fromTokenAmountMax < actualRequest) {
      errorCode = uint256(IMarketMaker.PMM_ERROR.REQUEST_TOO_MUCH);
      emit PMMSwap (
        pmmRequest.pathIndex, 
        subIndex, 
        pmmRequest.payer, 
        fromToken, 
        pmmRequest.toToken, 
        actualRequest, 
        0, 
        errorCode
      );
      return errorCode;
    }

    address tokenApprove = IApproveProxy(approveProxy).tokenApprove();
    SafeERC20.safeApprove(IERC20(fromToken), tokenApprove, actualRequest);
    // settle funds in MarketMaker, send funds to pmmAdapter
    _deposit(address(this), pmmAdapter, fromToken, actualRequest);
    bytes memory moreInfo = abi.encode(pmmRequest);
    uint256 toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this));
    errorCode = IAdapterWithResult(pmmAdapter).sellBase(address(this), address(0), moreInfo);
    toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this)) - toTokenAmount;
    SafeERC20.safeApprove(IERC20(fromToken), tokenApprove, 0);
    emit PMMSwap (
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

  //-------------------------------
  //------- Admin functions -------
  //-------------------------------

  function setApproveProxy(address newApproveProxy) external onlyOwner {
    approveProxy = newApproveProxy;

    emit ApproveProxyChanged(approveProxy);
  }

  //-------------------------------
  //------- Users Functions -------
  //-------------------------------

  function smartSwap(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    IMarketMaker.PMMSwapRequest[] calldata extraData
  ) external payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    // 1. transfer from token in
    require(baseRequest.fromTokenAmount > 0, "Route: fromTokenAmount must be > 0");
    BaseRequest memory localBaseRequest = baseRequest;
    address baseRequestFromToken = bytes32ToAddress(localBaseRequest.fromToken);
    returnAmount = IERC20(baseRequest.toToken).universalBalanceOf(msg.sender);
    _deposit(msg.sender, address(this), baseRequestFromToken, localBaseRequest.fromTokenAmount);

    // 2. check total batch amount
    {
      // invoid stack too deep
      uint256 totalBatchAmount;
      for (uint256 i = 0; i < batchesAmount.length; i++) {
        totalBatchAmount += batchesAmount[i];
      }
      require(
        totalBatchAmount <= localBaseRequest.fromTokenAmount,
        "Route: number of batches should be <= fromTokenAmount"
      );
    }

    // 3. try to replace the whole swap by pmm
    if (isReplace(localBaseRequest.fromToken)) {
      uint8 pmmIndex = getPmmIIndex(localBaseRequest.fromToken);
      if (_tryPmmSwap(baseRequestFromToken, localBaseRequest.fromTokenAmount, extraData[pmmIndex]) == 0) {
        _transferTokenToUser(localBaseRequest.toToken);

        returnAmount = IERC20(baseRequest.toToken).universalBalanceOf(msg.sender) - returnAmount;
        require(returnAmount >= baseRequest.minReturnAmount, "Route: Return amount is not enough");
        emit OrderRecord(baseRequestFromToken, baseRequest.toToken, msg.sender, localBaseRequest.fromTokenAmount, returnAmount);
      }
      return returnAmount;
    }

    // 4. execute batch
    for (uint256 i = 0; i < batches.length; i++) {
      // execute hop
      _exeHop(batchesAmount[i], batches[i], extraData);
    }

    // 5. transfer tokens to user
    _transferTokenToUser(baseRequestFromToken);
    _transferTokenToUser(baseRequest.toToken);

    // 6. check minReturnAmount
    returnAmount = IERC20(baseRequest.toToken).universalBalanceOf(msg.sender) - returnAmount;
    require(returnAmount >= baseRequest.minReturnAmount, "Route: Return amount is not enough");

    emit OrderRecord(baseRequestFromToken, baseRequest.toToken, msg.sender, localBaseRequest.fromTokenAmount, returnAmount);
  }
}

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
import "./interfaces/IXBridge.sol";

/// @title DexRouter
/// @notice Entrance of Split trading in Dex platform
/// @dev Entrance of Split trading in Dex platform
contract DexRouter is UnxswapRouter, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using UniversalERC20 for IERC20;

  // In the test scenario, we take it as a settable state and adjust it to a constant after it stabilizes
  address public approveProxy;
  address public wNativeRelayer;
  address public xBridge;

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
  event WNativeRelayerChanged(address wNativeRelayer);
  event XBridgeChanged(address newXBridge);
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

  modifier onlyXBridge() {
    require(msg.sender == xBridge, "only XBridge");
    _;
  }

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------

  function _exeForks(address payer, uint256 batchAmount, RouterPath memory path, bool isNotFirst) internal {
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
      // send the asset to the adapter

      _transferInternal(payer, path.assetTo[i], fromToken, _fromTokenAmount, isNotFirst);
      if (reserves) {
        IAdapter(path.mixAdapters[i]).sellQuote(address(this), poolAddress, path.extraData[i]);
      } else {
        IAdapter(path.mixAdapters[i]).sellBase(address(this), poolAddress, path.extraData[i]);
      }
    }
  }

  function _exeHop(
    address payer,
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
      if (_tryPmmSwap(payer, fromToken, batchAmount, extraData[pmmIndex], false) == 0 ) {
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
        if (_tryPmmSwap(payer, fromToken, batchAmount, extraData[pmmIndex], i > 0) == 0) {
          continue;
        }
      }

      // 3.2 execute forks
      _exeForks(payer, batchAmount, hops[i], i > 0);
    }
  }

  function _transferInternal(
    address payer,
    address to,
    address token,
    uint256 amount,
    bool isTransfer
  ) private {
    if (isTransfer || token == address(uint160(_WETH))) {
      SafeERC20.safeTransfer(IERC20(token), to, amount);
    } else {
      IApproveProxy(approveProxy).claimTokens(token, payer, to, amount);
    }
  }

  function _transferTokenToUser(address token, address to) internal {
    if ((IERC20(token).isETH())) {
      uint256 wethBal = IERC20(address(uint160(_WETH))).balanceOf(address(this));
      if (wethBal > 0) {
        IWETH(address(uint160(_WETH))).transfer(wNativeRelayer, wethBal);
        IWNativeRelayer(wNativeRelayer).withdraw(wethBal);
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
    IMarketMaker.PMMSwapRequest memory pmmRequest,
    bool isNotFirst
  ) internal returns (uint256 errorCode) {
    address pmmAdapter;
    uint256 subIndex;
    bytes memory extension = pmmRequest.extension;
    if (UniversalERC20.isETH(IERC20(fromToken))) {
      // market makers will get WETH
      fromToken = bytes32ToAddress(_WETH);
    }
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

    // settle funds in MarketMaker, send funds to pmmAdapter
    _transferInternal(payer, pmmAdapter, fromToken, actualRequest, isNotFirst);
    bytes memory moreInfo = abi.encode(pmmRequest);
    uint256 toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this));
    errorCode = IAdapterWithResult(pmmAdapter).sellBase(address(this), address(0), moreInfo);
    toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this)) - toTokenAmount;

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

  function _smartSwapInternal(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    IMarketMaker.PMMSwapRequest[] calldata extraData,
    address payer,
    address receiver
  ) internal returns (uint256) {
    uint256 returnAmount;
    // 1. transfer from token in
    BaseRequest memory localBaseRequest = baseRequest;
    require(localBaseRequest.fromTokenAmount > 0, "Route: fromTokenAmount must be > 0");
    address baseRequestFromToken = bytes32ToAddress(localBaseRequest.fromToken);
    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver);

    if (UniversalERC20.isETH(IERC20(address(uint160(localBaseRequest.fromToken))))) {
      IWETH(address(uint160(_WETH))).deposit{ value: localBaseRequest.fromTokenAmount }();
    } else if (address(uint160(localBaseRequest.fromToken)) == address(uint160(_WETH))) {
      IApproveProxy(approveProxy).claimTokens(
        address(uint160(localBaseRequest.fromToken)),
        payer,
        address(this),
        localBaseRequest.fromTokenAmount
      );
    }

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
      if (_tryPmmSwap(payer, baseRequestFromToken, localBaseRequest.fromTokenAmount, extraData[pmmIndex], false) == 0) {
        _transferTokenToUser(localBaseRequest.toToken, receiver);
        returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
        require(returnAmount >= localBaseRequest.minReturnAmount, "Route: Return amount is not enough");
        emit OrderRecord(baseRequestFromToken, localBaseRequest.toToken, receiver, localBaseRequest.fromTokenAmount, returnAmount);
        return returnAmount;
      }
    }

    // 4. execute batch
    for (uint256 i = 0; i < batches.length; i++) {
      // execute hop
      _exeHop(payer, batchesAmount[i], batches[i], extraData);
    }

    // 5. transfer tokens to user
    _transferTokenToUser(baseRequestFromToken, receiver);
    _transferTokenToUser(localBaseRequest.toToken, receiver);

    // 6. check minReturnAmount
    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
    require(returnAmount >= localBaseRequest.minReturnAmount, "Min return not reached");

    emit OrderRecord(baseRequestFromToken, localBaseRequest.toToken, receiver, localBaseRequest.fromTokenAmount, returnAmount);
    return returnAmount;
  }

  //-------------------------------
  //------- Admin functions -------
  //-------------------------------

  function setApproveProxy(address newApproveProxy) external onlyOwner {
    approveProxy = newApproveProxy;

    emit ApproveProxyChanged(approveProxy);
  }

  function setWNativeRelayer(address relayer) external onlyOwner {
    wNativeRelayer = relayer;

    emit WNativeRelayerChanged(relayer);
  }

  function setXBridge(address newXBridge) external onlyOwner {
    xBridge = newXBridge;
    emit XBridgeChanged(newXBridge);
  }

  //-------------------------------
  //------- Users Functions -------
  //-------------------------------

  function smartSwap(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    IMarketMaker.PMMSwapRequest[] calldata extraData
  ) public payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    returnAmount = _smartSwapInternal(baseRequest, batchesAmount, batches, extraData, msg.sender, msg.sender);
  }

  function smartSwapWithPermit(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    IMarketMaker.PMMSwapRequest[] calldata extraData,
    bytes calldata permit
  ) external payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    _permit(address(uint160(baseRequest.fromToken)), permit);
    return smartSwap(baseRequest, batchesAmount, batches, extraData);
  }

  function smartSwapByXBridge(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    IMarketMaker.PMMSwapRequest[] calldata extraData
  ) public payable isExpired(baseRequest.deadLine) nonReentrant onlyXBridge returns (uint256 returnAmount) {
    address payer = IXBridge(xBridge).payer();
    returnAmount = _smartSwapInternal(baseRequest, batchesAmount, batches, extraData, payer, msg.sender);
  }

  function unxswapByXBridge(
    IERC20 srcToken,
    uint256 amount,
    uint256 minReturn,
  // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools
  ) public payable onlyXBridge returns (uint256 returnAmount) {
    address payer = IXBridge(xBridge).payer();
    returnAmount = _unxswapInternal(srcToken, amount, minReturn, pools, payer);
  }
}
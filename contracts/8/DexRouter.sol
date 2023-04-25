// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./UnxswapRouter.sol";
import "./UnxswapV3Router.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IApproveProxy.sol";
import "./interfaces/IWNativeRelayer.sol";
import "./interfaces/IXBridge.sol";

import "./libraries/Permitable.sol";
import "./libraries/PMMLib.sol";
import "./libraries/EthReceiver.sol";
import "./libraries/WrapETHSwap.sol";

import "./storage/DexRouterStorage.sol";
import "./PMMRouter.sol";

/// @title DexRouterV1
/// @notice Entrance of Split trading in Dex platform
/// @dev Entrance of Split trading in Dex platform
contract DexRouter is OwnableUpgradeable, ReentrancyGuardUpgradeable, Permitable, EthReceiver, UnxswapRouter, UnxswapV3Router, DexRouterStorage, PMMRouter, WrapETHSwap {
  using UniversalERC20 for IERC20;

  bytes32 private constant _PMM_FLAG8_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
  bytes32 private constant _PMM_FLAG4_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
  bytes32 private constant _PMM_INDEX_I_MASK = 0x00ff000000000000000000000000000000000000000000000000000000000000;
  bytes32 private constant _PMM_INDEX_J_MASK = 0x0000ff0000000000000000000000000000000000000000000000000000000000;
  uint256 private constant _ORDER_ID_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
  uint256 private constant _WEIGHT_MASK = 0x00000000000000000000ffff0000000000000000000000000000000000000000;
  uint256 private constant _CALL_GAS_LIMIT = 5000;

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
  event PriorityAddressChanged(address priorityAddress, bool valid);
  event AdminChanged(address newAdmin);

  //-------------------------------
  //------- Modifier --------------
  //-------------------------------

  modifier isExpired(uint256 deadLine) {
    require(deadLine >= block.timestamp, "Route: expired");
    _;
  }

  modifier onlyPriorityAddress() {
    require(priorityAddresses[msg.sender] == true, "only priority");
    _;
  }

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------

  function _exeForks(address payer, uint256 batchAmount, RouterPath calldata path) private {
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

      _transferInternal(payer, path.assetTo[i], fromToken, _fromTokenAmount);

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
    RouterPath[] calldata hops,
    PMMLib.PMMSwapRequest[] calldata extraData
  ) private {
    uint8 pmmIndex;
    address fromToken = bytes32ToAddress(hops[0].fromToken);

    // try to replace this batch by pmm
    if (isReplace(hops[0].fromToken)) {
      pmmIndex = getPmmIIndex(hops[0].fromToken);
      if (_tryPmmSwap(payer, fromToken, batchAmount, extraData[pmmIndex]) == 0) {
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
        payer = address(this);
      }

      // 3.1 try to replace this hop by pmm
      if (isHopReplace(hops[i].fromToken)) {
        pmmIndex = getPmmJIndex(hops[i].fromToken);
        if (_tryPmmSwap(payer, fromToken, batchAmount, extraData[pmmIndex]) == 0) {
          continue;
        }
      }

      // 3.2 execute forks
      _exeForks(payer, batchAmount, hops[i]);
    }
  }

  function _transferInternal(
    address payer,
    address to,
    address token,
    uint256 amount
  ) private {
    if (payer == address(this)) {
      SafeERC20.safeTransfer(IERC20(token), to, amount);
    } else {
      IApproveProxy(approveProxy).claimTokens(token, payer, to, amount);
    }
  }

  function _transferTokenToUser(address token, address to) private {
    if ((IERC20(token).isETH())) {
      uint256 wethBal = IERC20(address(uint160(_WETH))).balanceOf(address(this));
      if (wethBal > 0) {
        IWETH(address(uint160(_WETH))).transfer(wNativeRelayer, wethBal);
        IWNativeRelayer(wNativeRelayer).withdraw(wethBal);
      }
      uint256 ethBal = address(this).balance;
      if (ethBal > 0) {
        (bool success, ) = payable(to).call{value: ethBal, gas: _CALL_GAS_LIMIT}('');
        require(success, "transfer native token failed");
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
    PMMLib.PMMSwapRequest calldata pmmRequest
  ) private returns (uint256 errorCode) {
    uint256 subIndex;
    bytes memory extension = pmmRequest.extension;
    if (UniversalERC20.isETH(IERC20(fromToken))) {
      // market makers will get WETH
      fromToken = _WETH;
    }
    assembly{
      subIndex := mload(add(extension, 0x20))
    }
    // check from token
    if (pmmRequest.fromToken != fromToken) {revert PMMLib.PMMErrorCode(uint256(PMMLib.PMM_ERROR.WRONG_FROM_TOKEN));}

    // settle funds in MarketMaker, send funds to pmmAdapter
    uint256 toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this));
    address tokenApprove = IApproveProxy(approveProxy).tokenApprove();
    SafeERC20.safeApprove(IERC20(pmmRequest.fromToken), tokenApprove, actualRequest);
    errorCode = _pmmSwapInternal(actualRequest, payer, address(this), pmmRequest, false, false);
    SafeERC20.safeApprove(IERC20(pmmRequest.fromToken), tokenApprove, 0);
    toTokenAmount = IERC20(pmmRequest.toToken).balanceOf(address(this)) - toTokenAmount;

    emit PMMLib.PMMSwap (
      pmmRequest.pathIndex,
      subIndex,
      errorCode
    );
    return errorCode;
  }

  function bytes32ToAddress(uint256 param) private pure returns (address result) {
    assembly {
      result := and(param, _ADDRESS_MASK)
    }
  }

  function isReplace(uint256 token) private pure returns (bool result) {
    assembly {
      result := and(token, _PMM_FLAG8_MASK)
    }
  }

  function isHopReplace(uint256 token) private pure returns (bool result) {
    assembly {
      result := and(token, _PMM_FLAG4_MASK)
    }
  }

  function getPmmIIndex(uint256 token) private pure returns (uint8 result) {
    assembly {
      result := shr(240, and(token, _PMM_INDEX_I_MASK))
    }
  }

  function getPmmJIndex(uint256 token) private pure returns (uint8 result) {
    assembly {
      result := shr(232, and(token, _PMM_INDEX_J_MASK))
    }
  }

  function _smartSwapInternal(
    BaseRequest memory baseRequest,
    uint256[] memory batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData,
    address payer,
    address receiver
  ) private returns (uint256 returnAmount) {
    // 1. transfer from token in
    BaseRequest memory _baseRequest = baseRequest;
    require(_baseRequest.fromTokenAmount > 0, "Route: fromTokenAmount must be > 0");
    address fromToken = bytes32ToAddress(_baseRequest.fromToken);
    returnAmount = IERC20(_baseRequest.toToken).universalBalanceOf(receiver);
    // bool fromInvest = payer == address(this);

    // In order to deal with ETH/WETH transfer rules in a unified manner, 
    // we do not need to judge according to fromToken.
    if (UniversalERC20.isETH(IERC20(fromToken))) {
      IWETH(address(uint160(_WETH))).deposit{ value: _baseRequest.fromTokenAmount }();
      payer = address(this);
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
        totalBatchAmount <= _baseRequest.fromTokenAmount,
        "Route: number of batches should be <= fromTokenAmount"
      );
    }

    // 3. try to replace the whole swap by pmm
    uint256 errorCode;
    if (isReplace(_baseRequest.fromToken)) {
      uint8 pmmIndex = getPmmIIndex(_baseRequest.fromToken);
      errorCode = _tryPmmSwap(payer, fromToken, _baseRequest.fromTokenAmount, extraData[pmmIndex]);
      if ( errorCode == 0) {
        _transferTokenToUser(_baseRequest.toToken, receiver);
        returnAmount = IERC20(_baseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
        require(returnAmount >= _baseRequest.minReturnAmount, "Route: Return amount is not enough");
        emit OrderRecord(fromToken, _baseRequest.toToken, tx.origin, _baseRequest.fromTokenAmount, returnAmount);
        return returnAmount;
      }
    }

    if (batches.length == 0 || batches[0].length == 0) {
      revert PMMLib.PMMErrorCode(errorCode);
    }

    // 4. execute batch
    for (uint256 i = 0; i < batches.length; ) {
      // execute hop, if the whole swap replacing by pmm fails, the funds will return to dexRouter	
      _exeHop(payer, batchesAmount[i], batches[i], extraData);
      unchecked {
        ++i;
      }
    }

    // 5. transfer tokens to user
    // _transferTokenToUser(fromToken, fromInvest ? tx.origin : receiver);
    _transferTokenToUser(_baseRequest.toToken, receiver);

    // 6. check minReturnAmount
    returnAmount = IERC20(_baseRequest.toToken).universalBalanceOf(receiver) - returnAmount;
    require(returnAmount >= _baseRequest.minReturnAmount, "Min return not reached");

    emit OrderRecord(fromToken, _baseRequest.toToken, tx.origin, _baseRequest.fromTokenAmount, returnAmount);
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

  function setPriorityAddress(address _priorityAddress, bool valid) external {
    require(msg.sender == tmpAdmin || msg.sender == admin || msg.sender == owner(), "na");
    priorityAddresses[_priorityAddress] = valid;
    emit PriorityAddressChanged(_priorityAddress, valid);
  }

  function setProtocolAdmin(address _newAdmin) external {
    require(msg.sender == tmpAdmin || msg.sender == admin || msg.sender == owner(), "na");
    admin = _newAdmin;
    emit AdminChanged(_newAdmin);
  }

  //-------------------------------
  //------- Users Functions -------
  //-------------------------------

  // function smartSwapWithPermit(
  //   BaseRequest calldata baseRequest,
  //   uint256[] calldata batchesAmount,
  //   RouterPath[][] calldata batches,
  //   PMMLib.PMMSwapRequest[] calldata extraData,
  //   bytes calldata permit
  // ) external payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
  //   _permit(address(uint160(baseRequest.fromToken)), permit);
  //   returnAmount = _smartSwapInternal(baseRequest, batchesAmount, batches, extraData, msg.sender, msg.sender);
  // }

  function smartSwapByOrderIdByXBridge(
    uint256 orderId,
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
  ) external payable isExpired(baseRequest.deadLine) nonReentrant onlyPriorityAddress returns (uint256 returnAmount) {
    emit SwapOrderId(orderId);
    (address payer, address receiver) = IXBridge(msg.sender).payerReceiver();
    returnAmount = _smartSwapInternal(baseRequest, batchesAmount, batches, extraData, payer, receiver);
  }

  function unxswapByOrderIdByXBridge(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools
  ) external payable onlyPriorityAddress returns (uint256 returnAmount) {
    emit SwapOrderId((srcToken & _ORDER_ID_MASK) >> 160);
    (address payer, address receiver) = IXBridge(msg.sender).payerReceiver();
    returnAmount = _unxswapInternal(IERC20(address(uint160(srcToken& _ADDRESS_MASK))), amount, minReturn, pools, payer, receiver);
  }

  function uniswapV3SwapToByXBridge(
    uint256 recipient,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
  ) external payable onlyPriorityAddress returns(uint256 returnAmount) {
    emit SwapOrderId((recipient & _ORDER_ID_MASK) >> 160);
    (address payer, address receiver) = IXBridge(msg.sender).payerReceiver();
    return _uniswapV3Swap(payer, payable(receiver), amount, minReturn, pools);
  }

  function smartSwapByOrderId(
    uint256 orderId,
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
  ) external payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    emit SwapOrderId(orderId);
    returnAmount = _smartSwapInternal(baseRequest, batchesAmount, batches, extraData, msg.sender, msg.sender);
  }

  function unxswapByOrderId(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools
  ) external payable returns (uint256 returnAmount) {
    emit SwapOrderId((srcToken & _ORDER_ID_MASK) >> 160);
    returnAmount = _unxswapInternal(IERC20(address(uint160(srcToken& _ADDRESS_MASK))), amount, minReturn, pools, msg.sender, msg.sender);
  }

  function smartSwapByInvest(
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData,
    address to
  ) external payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    address fromToken = bytes32ToAddress(baseRequest.fromToken);
    require(fromToken != _ETH, "Invalid source token");
    uint256 amount = IERC20(fromToken).balanceOf(address(this));
    BaseRequest memory newBaseRequest = BaseRequest ({
      fromToken : baseRequest.fromToken,
      toToken : baseRequest.toToken,
      fromTokenAmount : amount,
      minReturnAmount : baseRequest.minReturnAmount,
      deadLine : baseRequest.deadLine
    });
    uint256[] memory newBatchesAmount = new uint256[](batchesAmount.length);
    for (uint256 i = 0; i < batchesAmount.length; ++i) {
      newBatchesAmount[i] = batchesAmount[i] * amount / baseRequest.fromTokenAmount;
    }
    returnAmount = _smartSwapInternal(newBaseRequest, newBatchesAmount, batches, extraData, address(this), to);
  }

  /// @notice Same as `uniswapV3SwapTo` but calls permit first,
  /// allowing to approve token spending and make a swap in one transaction.
  /// @param recipient Address that will receive swap funds
  /// @param srcToken Source token
  /// @param amount Amount of source tokens to swap
  /// @param minReturn Minimal allowed returnAmount to make transaction commit
  /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
  /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
  /// See tests for examples
  function uniswapV3SwapToWithPermit(
    uint256 recipient,
    IERC20 srcToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools,
    bytes calldata permit
  ) external returns(uint256 returnAmount) {
    emit SwapOrderId((recipient & _ORDER_ID_MASK) >> 160);
    _permit(address(srcToken), permit);
    return _uniswapV3Swap(msg.sender, payable(bytes32ToAddress(recipient)), amount, minReturn, pools);
  }

  /// @notice Performs swap using Uniswap V3 exchange. Wraps and unwraps ETH if required.
  /// Sending non-zero `msg.value` for anything but ETH swaps is prohibited
  /// @param recipient Address that will receive swap funds
  /// @param amount Amount of source tokens to swap
  /// @param minReturn Minimal allowed returnAmount to make transaction commit
  /// @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
  function uniswapV3SwapTo(
    uint256 recipient,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
  ) external payable returns(uint256 returnAmount) {
    emit SwapOrderId((recipient & _ORDER_ID_MASK) >> 160);
    return _uniswapV3Swap(msg.sender, payable(bytes32ToAddress(recipient)), amount, minReturn, pools);
  }

  //-------------------------------
  //------- PMM swap -------
  //-------------------------------
  function initializePMMRouter(uint256 _feeRateAndReceiver) external onlyOwner {
    _initializePMMRouter(_feeRateAndReceiver);
  }

  function setPMMFeeConfig(uint256 _feeRateAndReceiver) external onlyOwner {
    _setPMMFeeConfig(_feeRateAndReceiver);
  }

  function PMMV2Swap(
    uint256 orderId,
    PMMLib.PMMBaseRequest calldata baseRequest,
    PMMLib.PMMSwapRequest calldata request
  ) external payable returns (uint256 returnAmount) {
    emit SwapOrderId(orderId);
    return _PMMV2Swap(msg.sender, msg.sender, baseRequest, request);
  }

  function PMMV2SwapByXBridge(
    uint256 orderId,
    PMMLib.PMMBaseRequest calldata baseRequest,
    PMMLib.PMMSwapRequest calldata request
  ) external payable onlyPriorityAddress nonReentrant returns (uint256 returnAmount) {
    emit SwapOrderId(orderId);
    (address payer, address receiver) = IXBridge(msg.sender).payerReceiver();
    return _PMMV2Swap(payer, receiver, baseRequest, request);
  }

  function PMMV2SwapByInvest(
    address receiver,
    PMMLib.PMMBaseRequest memory baseRequest,
    PMMLib.PMMSwapRequest calldata request
  ) external payable nonReentrant returns (uint256 returnAmount) {
    require(request.fromToken != _ETH, "Invalid source token");
    if (baseRequest.fromTokenAmount == 0) {
      baseRequest.fromTokenAmount = IERC20(request.fromToken).balanceOf(address(this));
    }
    return _PMMV2Swap(address(this), receiver, baseRequest, request);
  }
}
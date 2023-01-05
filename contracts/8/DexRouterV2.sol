// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./libraries/Permitable.sol";
import "./libraries/UniversalERC20.sol";
import "./libraries/EthReceiver.sol";
import "./interfaces/IXBridge.sol";
import "./interfaces/ISmartRouter.sol";

import "./UnxswapRouter.sol";
import "./UnxswapV3Router.sol";
import "./PMMRouter.sol";
import "./BalancerRouter.sol";
import "./CurveRouter.sol";

/// @title DexRouterV2
/// @notice Main contract incorporates a number of routers to perform swaps
contract DexRouterV2 is ReentrancyGuardUpgradeable, EthReceiver, OwnableUpgradeable, Permitable,
  UnxswapRouter, UnxswapV3Router, PMMRouter, CurveRouter /*BalancerRouter*/
{
  using UniversalERC20 for IERC20;

  address public smartRouter;
  address public xBridge;
  uint256 private constant _ORDER_ID_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;

  event SwapOrderId(uint256 id);
  event SmartRouterChanged(address indexed sender, address _smartRouter);
  event XBridgeChanged(address indexed sender, address _xBridge);

  error OnlySmartRouter();
  error OnlyXBridge();

  modifier onlyXBridge() {
    if(msg.sender != xBridge) {revert OnlyXBridge();}
    _;
  }

  function initialize(uint256 _feeRateAndReceiver) public initializer{
    __Ownable_init();
    __ReentrancyGuard_init();
    _initializePMMRouter(_feeRateAndReceiver);
  }

  /**
    * @notice Retrieves funds accidently sent directly to the contract address
    * @param token ERC20 token to retrieve
    * @param amount amount to retrieve
    */
  function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
    token.universalTransfer(payable(msg.sender), amount);
  }

  function setXBridge(address _xBridge) external onlyOwner {
    xBridge = _xBridge;
    emit XBridgeChanged(msg.sender, _xBridge);
  }

  //-------------------------------
  //------- unxswap -------
  //-------------------------------
  function unxswap(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools,
    bytes calldata permit
  ) external payable returns (uint256 returnAmount) {
    emit SwapOrderId((srcToken & _ORDER_ID_MASK) >> 160);
    if (permit.length > 0) {
      _permit(address(uint160(srcToken)), permit);
    }
    returnAmount = _unxswapInternal(IERC20(bytes32ToAddress(srcToken)), amount, minReturn, pools, msg.sender, msg.sender);
  }

  function unxswapForExactTokens(
    uint256 srcToken,
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata pools,
    bytes calldata permit
  ) external payable returns (uint256 returnAmount) {
    if (permit.length > 0) {
      _permit(address(uint160(srcToken)), permit);
    }
    return _unxswapForExactTokensInternal(IERC20(bytes32ToAddress(srcToken)), amountOut, amountInMax, pools);
  }

  function unxswapByOrderIdByXBridge(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    // solhint-disable-next-line no-unused-vars
    bytes32[] calldata pools
  ) external payable onlyXBridge returns (uint256 returnAmount) {
    emit SwapOrderId((srcToken & _ORDER_ID_MASK) >> 160);
    (address payer, address receiver) = IXBridge(xBridge).payerReceiver();
    returnAmount = _unxswapInternal(IERC20(bytes32ToAddress(srcToken)), amount, minReturn, pools, payer, receiver);
  }

  //-------------------------------
  //------- uniswapV3Swap -------
  //-------------------------------

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
  function setPMMFeeConfig(uint256 _feeRateAndReceiver) external onlyOwner {
    _setPMMFeeConfig(_feeRateAndReceiver);
  }

  function PMMV2Swap(
    PMMLib.PMMBaseRequest calldata baseRequest,
    PMMLib.PMMSwapRequest calldata request
  ) public payable nonReentrant returns (uint256 returnAmount) {
    return _PMMV2Swap(baseRequest, request);
  }

  function PMMV2SwapFromSmartRouter(
    uint256 actualAmountRequest,
    address fromTokenpayer,
    PMMLib.PMMSwapRequest calldata request
  ) external returns (uint256 errorCode) {
    if (msg.sender != smartRouter) {revert OnlySmartRouter();}
    return _swapInternal(actualAmountRequest, fromTokenpayer, request, false, false);
  }

  //-------------------------------
  //------- smart swap -------
  //-------------------------------
  function setSmartRouter(address _smartRouter) external onlyOwner {
    smartRouter = _smartRouter;
    emit SmartRouterChanged(msg.sender, _smartRouter);
  }

  function smartSwap(
    uint256 orderId,
    ISmartRouter.BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    ISmartRouter.RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData,
    bytes calldata permit
  ) external payable returns (uint256 returnAmount) {
    emit SwapOrderId(orderId);
    if (permit.length > 0) {
      _permit(address(uint160(baseRequest.fromToken)), permit);
    }
    returnAmount = ISmartRouter(smartRouter).smartSwap{value: msg.value}(baseRequest, batchesAmount, batches, extraData, msg.sender,msg.sender);
  }

  function smartSwapByOrderIdByXBridge(
    uint256 orderId,
    ISmartRouter.BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    ISmartRouter.RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
  ) external payable  onlyXBridge returns (uint256 returnAmount) {
    emit SwapOrderId(orderId);
    (address payer, address receiver) = IXBridge(xBridge).payerReceiver();
    returnAmount = ISmartRouter(smartRouter).smartSwap{value: msg.value}(baseRequest, batchesAmount, batches, extraData, payer, receiver);
  }

  function uniswapV3SwapToByXBridge(
    uint256 recipient,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
  ) external payable onlyXBridge returns(uint256 returnAmount) {
      emit SwapOrderId((recipient & _ORDER_ID_MASK) >> 160);
      (address payer, address receiver) = IXBridge(xBridge).payerReceiver();
      return _uniswapV3Swap(payer, payable(receiver), amount, minReturn, pools);
  }

  function bytes32ToAddress(uint256 param) internal pure returns (address result) {
    assembly {
      result := and(param, _ADDRESS_MASK)
    }
  }
}
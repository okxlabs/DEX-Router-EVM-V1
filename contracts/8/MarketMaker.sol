// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/SafeERC20.sol";
import "./libraries/ECDSA.sol";
import "./libraries/draft-EIP712Upgradable.sol";
import "./interfaces/IApproveProxy.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniV3.sol";
import "./interfaces/IUniswapV2Factory.sol";

/// @title MarketMaker
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra detailsq
contract MarketMaker is OwnableUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradable {
  using SafeERC20 for IERC20;

  // ============ Storage ============
  // _ORDER_TYPEHASH = keccak256("PMMSwapRequest(uint256 pathIndex,address payer,address fromToken,address toToken,uint256 fromTokenAmountMax,uint256 toTokenAmountMax,uint256 salt,uint256 deadLine,bool isPushOrder,bytes extension)")
  bytes32 private constant _ORDER_TYPEHASH = 0x5d068ce469dcf41137bcb6c3e1894e076ad915392f28fda19ba41601d33c32a6;
  string private constant _NAME = "METAX MARKET MAKER";
  string private constant _VERSION = "1.0"; 

  // uint256 private constant VALID_PERIOD_MIN = 3600;
  address constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  bytes32 constant _SOURCE_TYPE_MASK = 0xff00000000000000000000000000000000000000000000000000000000000000;
  bytes32 constant _REVERSE_MASK = 0x0080000000000000000000000000000000000000000000000000000000000000;
  bytes32 constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

  // pmm payer => pmm signer
  mapping(address => address) public operator;
  mapping(uint256 => OrderStatus) public orderStatus;
  mapping(address => bool) public pmmAdapter;
  mapping(address => bool) public cancelers;

  address public weth;
  address public approveProxy;
  address public feeTo;
  uint256 public feeRate;
  address public backEnd;
  address public cancelerGuardian;
  address public uniV2Factory;

  enum PMM_ERROR {
    NO_ERROR,
    INVALID_OPERATOR,
    INVALID_BACKEND,
    QUOTE_EXPIRED,
    REQUEST_TOO_MUCH,
    ORDER_CANCELLED_OR_FINALIZED,
    REMAINING_AMOUNT_NOT_ENOUGH,
    FAIL_TO_CLAIM_TOKEN,
    WRONG_FROM_TOKEN
  }

  enum SourceType {
    UniV2,
    UniV3
  }

  // ============ Struct ============

  struct PMMSwapRequest {
      uint256 pathIndex;
      address payer;
      address fromToken;
      address toToken;
      uint256 fromTokenAmountMax;
      uint256 toTokenAmountMax;
      uint256 salt;
      uint256 deadLine;
      bool isPushOrder;
      bytes extension;
      // address pmmAdapter;
      // uint256 subIndex;
      // bytes signature;
      // uint256 source;  1byte type + 1byte bool（reverse） + 20 bytes address
  }

  struct OrderStatus {
    uint256 fromTokenAmountMax;
    uint256 fromTokenAmountUsed;
    bool cancelledOrFinalized;
  }

  // ============ Event ============

  event AddPmmAdapter(address indexed sender, address pmmAdapter);
  event RemovePmmAdapter(address indexed sender, address pmmAdapter);
  event ChangeFeeConfig(address indexed sender, address newFeeTo, uint256 newFeeRate);
  event SetApproveProxy(address indexed sender, address approveProxy);
  event SetBackEnd(address indexed sender, address backEnd);
  event SetCanceler(address sender, address[] newCanceler, bool[] state);
  event ChangeOperator(address indexed payer, address operator);
  event SetCancelerGuardian(address sender, address newCancelerGuardian);
  event CancelQuotes(address sender, uint256[] pathIndex);
  event SetUniV2Factory(address sender, address newUniV2Factory);
  event PriceProtected(uint256 amount, uint256 protectedAmount);


  function initialize(
    address _weth,
    address _feeTo,
    uint256 _feeRate,
    address _backEnd,
    address _cancelerGuardian
  ) public initializer {
    __Ownable_init();
    _EIP712_init(_NAME, _VERSION);
    require(_weth != address(0), "Wrong Address!");
    require(_feeTo != address(0), "Wrong Address!");
    require(_feeRate <= 100, "fee Rate cannot exceed 1%");
    require(
      _ORDER_TYPEHASH ==
        keccak256(
          "PMMSwapRequest(uint256 pathIndex,address payer,address fromToken,address toToken,uint256 fromTokenAmountMax,uint256 toTokenAmountMax,uint256 salt,uint256 deadLine,bool isPushOrder,bytes extension)"
        ),
      "Wrong _ORDER_TYPEHASH"
    );
    weth = _weth;
    feeTo = _feeTo;
    feeRate = _feeRate;
    backEnd = _backEnd;
    cancelerGuardian = _cancelerGuardian;
  }

  // ============ Modifier ============

  modifier onlyPMMAdapter() {
    require(pmmAdapter[msg.sender], "Only PMMAdapter!");
    _;
  }

  // ============ OnlyOwner ============

  function addPmmAdapter(address _pmmAdapter) external onlyOwner {
    require(_pmmAdapter != address(0), "Wrong Address!");
    require(!pmmAdapter[_pmmAdapter], "PMMAdapter already exist!");
    pmmAdapter[_pmmAdapter] = true;

    emit AddPmmAdapter(msg.sender, _pmmAdapter);
  }

  function removePmmAdapter(address _pmmAdapter) external onlyOwner {
    require(_pmmAdapter != address(0), "Wrong Address!");
    require(pmmAdapter[_pmmAdapter], "PMMAdapter dose not exist!");
    pmmAdapter[_pmmAdapter] = false;

    emit RemovePmmAdapter(msg.sender, _pmmAdapter);
  }

  function feeConfig(address _feeTo, uint256 _feeRate) external onlyOwner {
    require(_feeTo != address(0), "Wrong Address!");
    require(_feeRate <= 100, "fee Rate cannot exceed 1%");
    feeTo = _feeTo;
    feeRate = _feeRate;

    emit ChangeFeeConfig(msg.sender, _feeTo, _feeRate);
  }

  function setApproveProxy(address newApproveProxy) external onlyOwner {
    approveProxy = newApproveProxy;
    emit SetApproveProxy(msg.sender, newApproveProxy);
  }

  function setBackEnd(address newBackEnd) external onlyOwner {
    backEnd = newBackEnd;
    emit SetBackEnd(msg.sender, newBackEnd);
  }

  function setCancelerGuardian(address newCancelerGuardian) external onlyOwner {
    cancelerGuardian = newCancelerGuardian;
    emit SetCancelerGuardian(msg.sender, newCancelerGuardian);
  }

  function setCanceler(address[] calldata canceler, bool[] calldata state) external {
    require(msg.sender == owner() || msg.sender == cancelerGuardian, "not authorized to set canceler");
    require(canceler.length == state.length, "length not match");
    for (uint256 i = 0; i < canceler.length; i++) {
      cancelers[canceler[i]] = state[i];
    }
    emit SetCanceler(msg.sender, canceler, state);
  }

  function setUniV2Factory(address newUniV2Factory) external onlyOwner {
    uniV2Factory = newUniV2Factory;
    emit SetUniV2Factory(msg.sender, newUniV2Factory);
  } 

  // ============ External ============

  function setOperator(address _operator) external {
    operator[msg.sender] = _operator;
    emit ChangeOperator(msg.sender, _operator);
  }

  function cancelQuotes(uint256[] calldata pathIndex) external{
    require(cancelers[msg.sender], "invalid canceler");
    for (uint256 i = 0; i < pathIndex.length; i++) {
      orderStatus[pathIndex[i]].cancelledOrFinalized = true;
    } 
    emit CancelQuotes(msg.sender, pathIndex);
  }

  function queryOrderStatus(uint256[] calldata pathIndex) external view returns (OrderStatus[] memory) {
    uint256 len = pathIndex.length;
    OrderStatus[] memory status = new OrderStatus[](len);
    for (uint256 i = 0; i < len; i++) {
      status[i] = (orderStatus[pathIndex[i]]);
    }
    return status;
  }

  function swap(
    uint256 actualAmountRequest,
    PMMSwapRequest memory request
  ) external onlyPMMAdapter nonReentrant returns (uint256 errorCode) {
    bytes32 digest = _hashTypedDataV4(hashOrder(request));
    errorCode = validateSigBatch(digest, request.payer, request.extension);
    if (errorCode > 0) {
      return errorCode;
    }
    errorCode = updateOrder(actualAmountRequest, request);
    if (errorCode > 0) {
      return errorCode;
    }

    // get transfer amount of toToken
    uint256 amount = (actualAmountRequest * request.toTokenAmountMax) / request.fromTokenAmountMax;
    uint256 source;
    uint256 protectedAmount;
    bytes memory extension = request.extension;
    assembly{
      source := mload(add(extension, 0xe0))
    }
    protectedAmount = _getProtectedAmount(request.fromToken, request.toToken, actualAmountRequest, source);
    if (amount > protectedAmount && protectedAmount != 0) {
      amount = protectedAmount;
      emit PriceProtected(amount, protectedAmount);
    }
    // get toToken address
    IERC20 token = IERC20(request.toToken);
    if (request.toToken == _ETH_ADDRESS) {
      token = IERC20(weth);
    }

    // try to transfer market maker's funds to "this"      
    try IApproveProxy(approveProxy).claimTokens(address(token), request.payer, address(this), amount) {
      if (feeTo != address(0) && feeRate != 0) {
        uint256 fee = (amount * feeRate) / 10000;
        token.safeTransfer(feeTo, fee);
        amount -= fee;
      }
      token.safeTransfer(msg.sender, amount);
      // transfer user's funds to market maker
      IApproveProxy(approveProxy).claimTokens(request.fromToken, msg.sender, request.payer, actualAmountRequest);

      // emit Swap(request.pathIndex, request.payer, request.fromToken, request.toToken, actualAmountRequest, amount);
      errorCode = uint256(PMM_ERROR.NO_ERROR);
    } catch {
      errorCode = uint256(PMM_ERROR.FAIL_TO_CLAIM_TOKEN);
    }
  }

  // ============ Internal ============

  /// @dev Get the struct hash of a PMMSwapRequest.
  /// @param order The SwapRequest.
  /// @return structHash The struct hash of the order.
  function hashOrder(PMMSwapRequest memory order) internal pure returns (bytes32 structHash) {
    assembly {
      let mem := mload(0x40)
      mstore(mem, _ORDER_TYPEHASH)
      // order.pathIndex;
      mstore(add(mem, 0x20), and(_ADDRESS_MASK, mload(order)))
      // order.payer;
      mstore(add(mem, 0x40), and(_ADDRESS_MASK, mload(add(order, 0x20))))
      // order.fromToken;
      mstore(add(mem, 0x60), and(_ADDRESS_MASK, mload(add(order, 0x40))))
      // order.toToken;
      mstore(add(mem, 0x80), mload(add(order, 0x60)))
      // order.fromTokenAmountMax;
      mstore(add(mem, 0xA0), mload(add(order, 0x80)))
      // order.toTokenAmountMax;
      mstore(add(mem, 0xC0), mload(add(order, 0xA0)))
      // order.salt;
      mstore(add(mem, 0xE0), mload(add(order, 0xC0)))
      // order.deadLine;
      mstore(add(mem, 0x100), mload(add(order, 0xE0)))
      // order.isPushOrder;
      mstore(add(mem, 0x120), mload(add(order, 0x100)))

      structHash := keccak256(mem, 0x140)
    }
  }

  function validateSigBatch(
    bytes32 digest,
    address payer,
    bytes memory extension    
  ) internal view returns (uint256) {
    bytes32 operatorSigR;
    bytes32 operatorSigVs;
    bytes32 backEndSigR;
    bytes32 backEndSigVs;
    assembly{
      operatorSigR := mload(add(extension, 0x60))
      operatorSigVs := mload(add(extension, 0x80))
      backEndSigR := mload(add(extension, 0xa0))
      backEndSigVs := mload(add(extension, 0xc0))
    }

    address operatorAddress = ECDSA.recover(digest, operatorSigR, operatorSigVs);

    if (!validateOperatorSig(payer, operatorAddress)) {
      return uint256(PMM_ERROR.INVALID_OPERATOR);
    }

    address backEndAddress = ECDSA.recover(digest, backEndSigR, backEndSigVs);
    if (!validateBackEndSig(backEndAddress)) {
      return uint256(PMM_ERROR.INVALID_BACKEND);
    }

    return uint256(PMM_ERROR.NO_ERROR);
  }

  function validateOperatorSig(address payer, address operatorAddress) internal view returns (bool) {
    if (operatorAddress == payer || operatorAddress == operator[payer]) {
      return true;
    }
    return false;
  }

  function validateBackEndSig(address backEndAddress) internal view returns (bool) {
    if (backEndAddress == backEnd){
      return true;
    }
    return false;
  }

  function updateOrder(
    uint256 actualAmountRequest,
    PMMSwapRequest memory order
  ) internal returns (uint256) {
    if (order.deadLine < block.timestamp) {
      return uint256(PMM_ERROR.QUOTE_EXPIRED);
    }

    if (actualAmountRequest > order.fromTokenAmountMax) {
      return uint256(PMM_ERROR.REQUEST_TOO_MUCH);
    }

    OrderStatus storage status = orderStatus[order.pathIndex];
    // in case of canceled or finalized order
    if (status.cancelledOrFinalized) {
      return uint256(PMM_ERROR.ORDER_CANCELLED_OR_FINALIZED);
    }

    // in case of pull order
    if (!order.isPushOrder) {
      status.cancelledOrFinalized = true;
      return uint256(PMM_ERROR.NO_ERROR);
    }

    // in case of push order
    if (order.fromTokenAmountMax > 0 && status.fromTokenAmountMax == 0) {
      // init push order
      status.fromTokenAmountMax = order.fromTokenAmountMax;
    }
    if (status.fromTokenAmountUsed + actualAmountRequest > order.fromTokenAmountMax) {
      return uint256(PMM_ERROR.REMAINING_AMOUNT_NOT_ENOUGH);
    }
    status.fromTokenAmountUsed += actualAmountRequest;

    return uint256(PMM_ERROR.NO_ERROR);
  }

  // =============== price protection ===============

  function _getProtectedAmount(
      address fromToken,
      address toToken,
      uint256 fromTokenAmount,
      uint256 source
      ) internal view returns (uint256 protectedAmount) {
          uint8 sourceType;
          bool isReverse;
          address sourceAddress;
          if (source == 0){
              (sourceType, isReverse, sourceAddress) = getDefaultSource(fromToken, toToken);
          } else {
              (sourceType, isReverse, sourceAddress) =  getSourceDetails(source);
          }
          if (sourceType == uint8(SourceType.UniV2)) {
              protectedAmount = _getProtectedAmountFromUniV2(fromTokenAmount, isReverse, sourceAddress);
          } else if (sourceType == uint8(SourceType.UniV3)) {
              protectedAmount = _getProtectedAmountFromUniV3(fromTokenAmount, isReverse, sourceAddress);
          }
          
  }

  // get protected toToken amount according to the spot price of uniV2
  function _getProtectedAmountFromUniV2(
          uint256 fromTokenAmount,
          bool isReverse,
          address source
      ) internal view returns (uint256 protectedAmount) {
      try IUniswapV2Pair(source).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
        if (reserve0 == 0 || reserve1 == 0){
          return 0;
        }
        if (isReverse) {
            protectedAmount = fromTokenAmount * uint256(reserve0) / uint256(reserve1);
        } else {
            protectedAmount = fromTokenAmount * uint256(reserve1) / uint256(reserve0);
        }
      } catch {}
  }

  // get protected toToken amount according to the sqrtPriceX96 of uniV3
  function _getProtectedAmountFromUniV3(
          uint256 fromTokenAmount,
          bool isReverse,
          address source
      ) internal view returns (uint256 protectedAmount) {
      try IUniV3(source).slot0() returns (uint160 sqrtPriceX96, int24, uint16, uint16, uint16, uint8, bool){
        if (sqrtPriceX96 == 0) {
          return 0;
        }
        if (isReverse) {
          // r1 > sqrt(r1/r0) && sqrt(r1*r0) > sqrt(r1/r0), so this will never overflow
          protectedAmount = ((fromTokenAmount << 96) / sqrtPriceX96 << 96) / sqrtPriceX96;
        } else {
          // r0 * sqrt(r1/r0) > 0 && sqrt(r0*r1) * sqrt(r1/r0) > 0, so this will also never overflow
          protectedAmount = (fromTokenAmount * sqrtPriceX96 >> 96) * sqrtPriceX96 >> 96;
        }  
      } catch {}
  }

  function getSourceDetails(uint256 source) internal pure returns (uint8 sorceType, bool isReverse, address sourceAddress) {
      assembly {
          sorceType := shr(248, and(source, _SOURCE_TYPE_MASK))
          isReverse := and(source, _REVERSE_MASK)
          sourceAddress := and(source, _ADDRESS_MASK)
      }
  }

  // if no source provided, get source datas from uniV2
  function getDefaultSource(address fromToken, address toToken) internal view returns (uint8 sorceType, bool isReverse, address sourceAddress) {
    address pair = IUniswapV2Factory(uniV2Factory).getPair(fromToken, toToken);
    address token0 = IUniswapV2Pair(pair).token0();
    if (token0 == toToken) {
        isReverse = true;
    }
    sorceType = uint8(SourceType.UniV2);
    sourceAddress = pair;
  }
}

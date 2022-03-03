// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./TokenApproveProxy.sol";
import "./UnxswapRouter.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IApproveProxy.sol";

import "./libraries/SafeMath.sol";

/// @title DexRouter
/// @notice Entrance of Split trading in Dex platform
/// @dev Entrance of Split trading in Dex platform
contract DexRouter is UnxswapRouter, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using UniversalERC20 for IERC20;

  address public WETH;
  address public approveProxy;
  address public tokenApprove;

  struct BaseRequest {
    address fromToken;
    address toToken;
    uint256 fromTokenAmount;
    uint256 minReturnAmount;
    uint256 deadLine;
  }

  struct SwapRequest {
    address fromToken;
    uint256[] fromTokenAmount;
  }

  struct RouterPath {
    address[] mixAdapters;
    address[] mixPairs;
    address[] assetTo;
    uint256[] weight;
    uint256[] directions;
    bytes[] extraData;
  }

  // receive() external payable {}

  function initialize(address payable _weth) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    WETH = _weth;
  }

  //-------------------------------
  //------- Events ----------------
  //-------------------------------

  event OrderRecord(address fromToken, address toToken, address sender, uint256 fromAmount, uint256 returnAmount);

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

  function _exeSwap(
    uint256 layerAmount,
    SwapRequest calldata request,
    RouterPath calldata path
  ) internal {
    // execute multiple Adapters for a transaction pair
    for (uint256 i = 0; i < path.mixAdapters.length; i++) {
      uint256 _fromTokenAmount = layerAmount.mul(path.weight[i]).div(10000);
      SafeERC20.safeApprove(IERC20(request.fromToken), tokenApprove, _fromTokenAmount);
      // send the asset to adapter
      _deposit(address(this), path.assetTo[i], request.fromToken, _fromTokenAmount);
      if (path.directions[i] == 1) {
        IAdapter(path.mixAdapters[i]).sellBase(address(this), path.mixPairs[i], path.extraData[i]);
      } else {
        IAdapter(path.mixAdapters[i]).sellQuote(address(this), path.mixPairs[i], path.extraData[i]);
      }
      SafeERC20.safeApprove(IERC20(request.fromToken), tokenApprove, 0);
    }
  }

  function _preExeSwap(uint256 layerAmount, SwapRequest[] calldata request, RouterPath[] calldata layer) internal {
    for (uint256 i = 0; i < layer.length; i++) {
      require(layer[i].mixPairs.length > 0, "Route: pairs empty");
      require(layer[i].mixPairs.length == layer[i].mixAdapters.length, "Route: pair adapter not match");
      require(layer[i].mixPairs.length == layer[i].assetTo.length, "Route: pair assetto not match");
      require(layer[i].mixPairs.length == layer[i].weight.length, "Route: weight not match");
      _exeSwap(layerAmount, request[i], layer[i]);
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
        IWETH(WETH).deposit{ value: amount }();
        if (to != address(this)) {
          SafeERC20.safeTransfer(IERC20(WETH), to, amount);
        }
      }
    } else {
      IApproveProxy(approveProxy).claimTokens(token, from, to, amount);
    }
  }

  //-------------------------------
  //------- Admin functions -------
  //-------------------------------

  function setApproveProxy(address newApproveProxy) external onlyOwner {
    approveProxy = newApproveProxy;
  }

  function setTokenAprrove(address newTokenApprove) external onlyOwner {
    tokenApprove = newTokenApprove;
  }

  //-------------------------------
  //------- Users Functions -------
  //-------------------------------

  function smartSwap(
    BaseRequest calldata baseRequest,
    uint256[] calldata branchesAmount,
    SwapRequest[][] calldata request,
    RouterPath[][] calldata layers
  ) external payable isExpired(baseRequest.deadLine) nonReentrant returns (uint256 returnAmount) {
    require(baseRequest.fromTokenAmount > 0, "Route: fromTokenAmount must be > 0");
    BaseRequest memory localBaseRequest = baseRequest;
    uint256 toTokenOriginBalance = IERC20(baseRequest.toToken).universalBalanceOf(msg.sender);
    _deposit(msg.sender, address(this), localBaseRequest.fromToken, localBaseRequest.fromTokenAmount);

    uint256 totalBranchAmount = 0;
    for (uint256 i = 0; i < layers.length; i++) {
      totalBranchAmount += branchesAmount[i];
    }
    require(totalBranchAmount <= localBaseRequest.fromTokenAmount, "Route: number of branches should be <= fromTokenAmount");

    for (uint256 i = 0; i < layers.length; i++) {
      uint256 layerAmount = branchesAmount[i];
      // uint256 layerAmount = localBaseRequest.fromTokenAmount.mul(branchesAmount[i]).div(10000);
      _preExeSwap(layerAmount, request[i], layers[i]);
    }

    returnAmount = IERC20(localBaseRequest.toToken).universalBalanceOf(msg.sender).sub(toTokenOriginBalance);
    require(returnAmount >= localBaseRequest.minReturnAmount, "Route: Return amount is not enough");

    address tmpFromToken = localBaseRequest.fromToken;
    address tmpToToken = localBaseRequest.toToken;
    if (UniversalERC20.isETH(IERC20(tmpToToken))) {
      uint256 remainAmount = IERC20(tmpFromToken).universalBalanceOf(address(this));
      IWETH(WETH).withdraw(remainAmount);
      payable(msg.sender).transfer(remainAmount);
      if (IERC20(tmpFromToken).universalBalanceOf(address(this)) > 0) {
        SafeERC20.safeTransfer(
          IERC20(tmpFromToken),
          msg.sender,
          IERC20(tmpFromToken).universalBalanceOf(address(this))
        );
      }
    } else {
      if (IERC20(tmpToToken).universalBalanceOf(address(this)) > 0) {
        SafeERC20.safeTransfer(IERC20(tmpToToken), msg.sender, IERC20(tmpToToken).universalBalanceOf(address(this)));
      }
      if (UniversalERC20.isETH(IERC20(tmpFromToken))) {
        uint256 remainAmount = IERC20(tmpFromToken).universalBalanceOf(address(this));
        IWETH(WETH).withdraw(remainAmount);
        payable(msg.sender).transfer(remainAmount);
      } else {
        if (IERC20(tmpFromToken).universalBalanceOf(address(this)) > 0) {
          SafeERC20.safeTransfer(
            IERC20(tmpFromToken),
            msg.sender,
            IERC20(tmpFromToken).universalBalanceOf(address(this))
          );
        }
      }
    }

    emit OrderRecord(localBaseRequest.fromToken, localBaseRequest.toToken, msg.sender, localBaseRequest.fromTokenAmount, returnAmount);
  }
}

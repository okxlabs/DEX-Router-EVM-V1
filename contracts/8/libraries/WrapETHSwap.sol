/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/CommonUtils.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IWNativeRelayer.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IApproveProxy.sol";

/// @title Base contract with common payable logics
abstract contract WrapETHSwap is CommonUtils {

  uint256 private constant SWAP_AMOUNT = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  
  function swapWrap(uint256 orderId, uint256 rawdata) external payable {
    bool reversed;
    uint128 amount;
    assembly {
      reversed := and(rawdata, _REVERSE_MASK)
      amount := and(rawdata, SWAP_AMOUNT)
    }
    require(amount > 0, "amount must be > 0");
    if (reversed) {
      IApproveProxy(_APPROVE_PROXY).claimTokens(_WETH, msg.sender, _WNATIVE_RELAY, amount);
      IWNativeRelayer(_WNATIVE_RELAY).withdraw(amount);
      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success, "transfer native token failed");
    } else {
      require(msg.value == amount, "value not equal amount");
      IWETH(_WETH).deposit{value: amount}();
      SafeERC20.safeTransfer(IERC20(_WETH), msg.sender, amount);
    }
    emit SwapOrderId(orderId);
    emit OrderRecord(reversed ? _WETH : _ETH, reversed ? _ETH: _WETH, msg.sender, amount, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IWETH.sol";
import "../libraries/RevertReasonParser.sol";

contract WNativeRelayer is OwnableUpgradeable, ReentrancyGuardUpgradeable {

  address private wnative;
  mapping(address => bool) private okCallers;

  event SetCaller(address indexed caller, bool isAllowed);
  event SetWNative(address newWNative);

  function initialize(address _wnative) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    wnative = _wnative;

    emit SetWNative(_wnative);
  }

  modifier onlyWhitelistCaller() {
    require(okCallers[msg.sender] == true, "WNativeRelayer::onlyWhitelistedCaller:: !okCaller");
    _;
  }

  function setCallerOk(address[] calldata whitelistedCallers, bool isOk) external onlyOwner {
    uint256 len = whitelistedCallers.length;
    for (uint256 idx = 0; idx < len; idx++) {

      okCallers[whitelistedCallers[idx]] = isOk;
      
      emit SetCaller(whitelistedCallers[idx], isOk);
    }
  }

  function withdraw(uint256 _amount) external onlyWhitelistCaller nonReentrant {
    IWETH(wnative).withdraw(_amount);
    (bool success, ) = msg.sender.call{ value: _amount }("");
    require(success, "WNativeRelayer::onlyWhitelistedCaller:: can't withdraw");
  }

  receive() external payable {}
}

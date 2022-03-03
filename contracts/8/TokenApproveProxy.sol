// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IApprove.sol";
import "./interfaces/IApproveProxy.sol";

/// @title Allow different version dexproxy to claim from Approve
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract TokenApproveProxy is IApproveProxy, OwnableUpgradeable {
  mapping(address => bool) public allowedApprove;
  address public tokenApprove;

  function initialize() public initializer {
    __Ownable_init();
  }

  //-------------------------------
  //------- Events ----------------
  //-------------------------------

  event AddNewProxy(address newProxy);
  event RemoveNewProxy(address oldProxy);

  //-------------------------------
  //------- Internal Functions ----
  //-------------------------------

  //-------------------------------
  //------- Admin functions -------
  //-------------------------------

  function addProxy(address _newProxy) external onlyOwner {
    allowedApprove[_newProxy] = true;
    emit AddNewProxy(_newProxy);
  }

  function removeProxy(address _oldProxy) public onlyOwner {
    allowedApprove[_oldProxy] = false;
    emit RemoveNewProxy(_oldProxy);
  }

  function setTokenApprove(address _tokenApprove) external onlyOwner {
    tokenApprove = _tokenApprove;
  }

  //-------------------------------
  //------- Users Functions -------
  //-------------------------------

  function claimTokens(
    address _token,
    address _who,
    address _dest,
    uint256 _amount
  ) external override {
    require(allowedApprove[msg.sender], "ApproveProxy: Access restricted");
    IApprove(tokenApprove).claimTokens(_token, _who, _dest, _amount);
  }

  function isAllowedProxy(address _proxy) external view override returns (bool) {
    return allowedApprove[_proxy];
  }
}

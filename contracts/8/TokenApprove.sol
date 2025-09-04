// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";

/// @title Handle authorizations in dex platform
/// @notice This contract is used to manage token approvals and ensure safe token transfers on a DEX platform.
/// @dev This contract utilizes the SafeERC20 library for secure token transfers and provides functionality to update the approval proxy address.
contract TokenApprove is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice The address authorized to initiate token transfers on behalf of users.
    address public tokenApproveProxy;

    /// @notice Initializes the contract by setting the token approval proxy address.
    /// @param _tokenApproveProxy The address authorized to initiate token transfers.
    function initialize(address _tokenApproveProxy) public initializer {
        __Ownable_init();
        tokenApproveProxy = _tokenApproveProxy;
    }

    //-------------------------------
    //------- Events ----------------
    //-------------------------------

    /// @notice Emitted when the token approval proxy address is updated.
    /// @param oldProxy The previous proxy address.
    /// @param newProxy The new proxy address.
    event ProxyUpdate(address indexed oldProxy, address indexed newProxy);

    //---------------------------------
    //------- Admin functions ---------
    //---------------------------------

    /// @notice Updates the token approval proxy address.
    /// @param _newTokenApproveProxy The new address authorized to initiate token transfers.
    /// @dev Can only be called by the contract owner.
    function setApproveProxy(address _newTokenApproveProxy) external onlyOwner {
        emit ProxyUpdate(tokenApproveProxy, _newTokenApproveProxy);
        tokenApproveProxy = _newTokenApproveProxy;
    }

    //---------------------------------
    //-------  User Functions --------
    //---------------------------------

    /// @notice Transfers tokens from one address to another on behalf of the token owner, using a pre-approved allowance.
    /// @param _token The address of the token to be transferred.
    /// @param _who The address of the token owner (the sender).
    /// @param _dest The address of the recipient (the receiver).
    /// @param _amount The amount of tokens to be transferred.
    /// @dev This function can only be called by the address set as `tokenApproveProxy`.
    function claimTokens(
        address _token,
        address _who,
        address _dest,
        uint256 _amount
    ) external {
        require(
            msg.sender == tokenApproveProxy,
            "TokenApprove: Access restricted"
        );
        if (_amount > 0) {
            IERC20(_token).safeTransferFrom(_who, _dest, _amount);
        }
    }
}

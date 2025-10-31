// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IApprove.sol";
import "./interfaces/IApproveProxy.sol";

/// @title Allow different version dexproxy to claim from Approve
/// @notice This contract acts as a proxy to manage and execute token approvals and transfers, ensuring that only authorized proxies can perform these operations. It is used in a DEX platform to handle token approvals and transfers securely.
/// @dev This contract implements the IApproveProxy interface and uses the OwnableUpgradeable pattern for access control. It maintains a list of allowed proxies and interacts with the IApprove contract to execute token transfers.
contract TokenApproveProxy is IApproveProxy, OwnableUpgradeable {
    /// @notice A mapping to keep track of addresses that are allowed to use this proxy for token approval and transfer.
    mapping(address => bool) public allowedApprove;

    /// @notice The address of the TokenApprove contract that this proxy interacts with.
    address public override tokenApprove;

    /// @notice Initializes the contract, setting up the owner.
    function initialize() public initializer {
        __Ownable_init();
    }

    //-------------------------------
    //------- Events ----------------
    //-------------------------------

    /// @notice Emitted when a new proxy address is added to the allowed list.
    /// @param newProxy The address of the new proxy added.
    event AddNewProxy(address newProxy);

    /// @notice Emitted when a proxy address is removed from the allowed list.
    /// @param oldProxy The address of the proxy removed.
    event RemoveNewProxy(address oldProxy);

    /// @notice Emitted when the TokenApprove contract address is updated.
    /// @param newTokenApprove The address of the new TokenApprove contract.
    event TokenApproveChanged(address newTokenApprove);

    //-------------------------------
    //------- Admin functions -------
    //-------------------------------

    /// @notice Adds a new proxy address to the list of allowed proxies.
    /// @param _newProxy The address of the new proxy to add.
    /// @dev Can only be called by the contract owner.
    function addProxy(address _newProxy) external onlyOwner {
        allowedApprove[_newProxy] = true;
        emit AddNewProxy(_newProxy);
    }

    /// @notice Removes a proxy address from the list of allowed proxies.
    /// @param _oldProxy The address of the proxy to remove.
    /// @dev Can only be called by the contract owner.
    function removeProxy(address _oldProxy) public onlyOwner {
        allowedApprove[_oldProxy] = false;
        emit RemoveNewProxy(_oldProxy);
    }

    /// @notice Sets the address of the TokenApprove contract that this proxy interacts with.
    /// @param _tokenApprove The address of the TokenApprove contract.
    /// @dev Can only be called by the contract owner.
    function setTokenApprove(address _tokenApprove) external onlyOwner {
        tokenApprove = _tokenApprove;
        emit TokenApproveChanged(_tokenApprove);
    }

    //-------------------------------
    //------- Users Functions -------
    //-------------------------------

    /// @notice Claims tokens on behalf of a user, transferring them from the user's account to a destination address.
    /// @param _token The address of the token to be transferred.
    /// @param _who The address of the token owner (the sender).
    /// @param _dest The address of the recipient (the receiver).
    /// @param _amount The amount of tokens to be transferred.
    /// @dev This function can only be called by an address that is in the list of allowed proxies. It delegates the actual transfer operation to the TokenApprove contract.
    function claimTokens(
        address _token,
        address _who,
        address _dest,
        uint256 _amount
    ) external override {
        require(allowedApprove[msg.sender], "ApproveProxy: Access restricted");
        IApprove(tokenApprove).claimTokens(_token, _who, _dest, _amount);
    }

    /// @notice Checks if a given address is an allowed proxy.
    /// @param _proxy The address to check.
    /// @return A boolean indicating if the address is an allowed proxy.
    /// @dev Provides a view function to check if a specific address is in the list of allowed proxies.
    function isAllowedProxy(
        address _proxy
    ) external view override returns (bool) {
        return allowedApprove[_proxy];
    }
}

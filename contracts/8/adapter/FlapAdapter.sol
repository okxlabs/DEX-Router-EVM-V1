// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAaveLendingPool.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";
import {ExactInputParams, IPortal} from "../interfaces/IPortal.sol";

/**
 * @title FlapAdapter
 * @notice Adapter contract for interacting with Flap Portal swaps
 * @dev Handles token swaps through Flap Portal with automatic NATIVE/WNATIVE wrapping/unwrapping
 */
contract FlapAdapter is IAdapter {
    using SafeERC20 for IERC20;

    /// @notice The Flap Portal contract address for executing swaps
    address public immutable FLAP_PORTAL;
    
    /// @notice The wrapped native token address (e.g., WETH, WOKB)
    address public immutable WNATIVE;
    
    /// @notice Address constant for native token representation
    address private constant NATIVE_TOKEN = address(0);

    /// @notice Emitted when the contract receives native tokens
    /// @param sender The address that sent the tokens
    /// @param amount The amount of tokens received
    event Received(address sender, uint256 amount);

    /**
     * @notice Constructs the FlapAdapter
     * @param flapPortal The address of the Flap Portal contract
     * @param wnative The address of the wrapped native token
     */
    constructor(address flapPortal, address wnative) {
        require(flapPortal != address(0), "FlapAdapter: Invalid portal address");
        require(wnative != address(0), "FlapAdapter: Invalid WNATIVE address");
        
        FLAP_PORTAL = flapPortal;
        WNATIVE = wnative;
    }

    /**
     * @notice Executes a sell base operation through Flap Portal
     * @param to The recipient address for output tokens
     * @param moreInfo Encoded ExactInputParams for the swap
     * @dev Pool parameter is unused as Flap Portal doesn't require pool specification
     */
    function sellBase(
        address to,
        address, // pool parameter not used for Flap Portal
        bytes memory moreInfo
    ) external override {
        _executeSwap(to, moreInfo);
    }

    /**
     * @notice Executes a sell quote operation through Flap Portal
     * @param to The recipient address for output tokens
     * @param moreInfo Encoded ExactInputParams for the swap
     * @dev Pool parameter is unused as Flap Portal doesn't require pool specification
     */
    function sellQuote(
        address to,
        address, // pool parameter not used for Flap Portal
        bytes memory moreInfo
    ) external override {
        _executeSwap(to, moreInfo);
    }

    /**
     * @notice Executes the complete swap operation with token handling
     * @param to The recipient address for output tokens
     * @param moreInfo Encoded ExactInputParams for the swap
     */
    function _executeSwap(address to, bytes memory moreInfo) internal {
        require(to != address(0), "FlapAdapter: Invalid recipient");
        
        ExactInputParams memory params = abi.decode(moreInfo, (ExactInputParams));
        bool outputRequiresWrapping = false;
        
        // Handle input token preparation
        if (params.inputToken == WNATIVE) {
            _unwrapInputToken(params);
        } else {
            // For non-WNATIVE input, prepare for native output
            params.outputToken = NATIVE_TOKEN;
            outputRequiresWrapping = true;
        }

        // Execute the swap
        _performSwap(params);

        // Handle output token wrapping if needed
        if (outputRequiresWrapping) {
            _wrapOutputToken();
        }

        // Transfer final tokens to recipient
        _transferOutput(to, params.outputToken, outputRequiresWrapping);
    }

    /**
     * @notice Unwraps WNATIVE input tokens to native tokens for the swap
     * @param params The swap parameters to modify
     */
    function _unwrapInputToken(ExactInputParams memory params) internal {
        uint256 wnativeBalance = IERC20(WNATIVE).balanceOf(address(this));
        require(wnativeBalance > 0, "FlapAdapter: No WNATIVE balance");
        
        IWETH(WNATIVE).withdraw(wnativeBalance);
        params.inputToken = NATIVE_TOKEN;
        params.inputAmount = wnativeBalance;
    }

    /**
     * @notice Wraps native tokens to WNATIVE after the swap
     */
    function _wrapOutputToken() internal {
        uint256 nativeBalance = address(this).balance;
        if (nativeBalance > 0) {
            IWETH(WNATIVE).deposit{value: nativeBalance}();
        }
    }

    /**
     * @notice Performs the actual swap through Flap Portal
     * @param params The swap parameters
     */
    function _performSwap(ExactInputParams memory params) internal {
        require(params.inputAmount > 0, "FlapAdapter: Invalid input amount");
        
        if (params.inputToken == NATIVE_TOKEN) {
            // Native token input - send value with the call
            require(address(this).balance >= params.inputAmount, "FlapAdapter: Insufficient native balance");
            IPortal(FLAP_PORTAL).swapExactInput{value: params.inputAmount}(params);
        } else {
            // ERC20 token input - approve and swap
            IERC20(params.inputToken).safeApprove(FLAP_PORTAL, params.inputAmount);
            IPortal(FLAP_PORTAL).swapExactInput(params);
        }
    }

    /**
     * @notice Transfers output tokens to the recipient
     * @param to The recipient address
     * @param outputToken The output token address
     * @param outputWasWrapped Whether the output was wrapped during processing
     */
    function _transferOutput(
        address to,
        address outputToken,
        bool outputWasWrapped
    ) internal {
        if (outputWasWrapped) {
            // Transfer wrapped native tokens to recipient
            _transferWrappedTokens(to);
        } else {
            // Transfer regular tokens to recipient
            _transferTokens(to, outputToken);
        }

        // Handle any remaining native token dust
        _transferDust(to);
    }

    /**
     * @notice Transfers wrapped native tokens to recipient
     * @param to The recipient address
     */
    function _transferWrappedTokens(address to) internal {
        uint256 wnativeBalance = IERC20(WNATIVE).balanceOf(address(this));
        if (wnativeBalance > 0) {
            IERC20(WNATIVE).safeTransfer(to, wnativeBalance);
        }
    }

    /**
     * @notice Transfers regular ERC20 tokens to recipient
     * @param to The recipient address
     * @param token The token address to transfer
     */
    function _transferTokens(address to, address token) internal {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(token).safeTransfer(to, tokenBalance);
        }
    }

    /**
     * @notice Transfers any remaining native token dust to recipient
     * @param to The recipient address
     */
    function _transferDust(address to) internal {
        uint256 dust = address(this).balance;
        if (dust > 0) {
            (bool success, ) = to.call{value: dust}("");
            require(success, "FlapAdapter: Dust transfer failed");
        }
    }

    /**
     * @notice Receives native tokens sent to the contract
     * @dev Required for receiving native tokens from WNATIVE unwrapping and swaps
     */
    receive() external payable {
        require(msg.value > 0, "FlapAdapter: No value received");
        emit Received(msg.sender, msg.value);
    }
}

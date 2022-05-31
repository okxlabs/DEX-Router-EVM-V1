// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IApproveProxy.sol";

/// @title XBridge
/// @notice Entrance for Bridge
/// @dev Entrance for Bridge
contract MockXBridge is PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct SwapAndBridgeRequest {
        address fromToken; // the source token
        address toToken;  // the token to be bridged
        address to; // the address to be bridged to
        uint256 adaptorId;
        uint256 toChainId;
        uint256 fromTokenAmount; // the source token amount
        uint256 toTokenMinAmount;
        uint256 toChainToTokenMinAmount;
        bytes   data;
        bytes   dexData;  // the call data for dexRouter
    }

    //-------------------------------
    //------- storage ---------------
    //-------------------------------
    mapping(uint256 => address) public adaptorInfo;

    address public approveProxy;

    address public dexRouter;

    address public payer; // temp msg.sender when swap

    // initialize
    function initialize() public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
    }
    //-------------------------------
    //------- Events ----------------
    //-------------------------------
    event ApproveProxyChanged(address _approveProxy);
    event DexRouterChanged(address _dexRouter);
    event LogSwapAndBridgeTo(
        uint256 indexed _adaptorId,
        address _from,
        address _to,
        address _fromToken,
        uint256 fromAmount,
        address _toToken,
        uint256 _toAmount
    );

    //-------------------------------
    //------- Modifier --------------
    //-------------------------------

    //-------------------------------
    //------- Internal Functions ----
    //-------------------------------
    function _deposit(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        IApproveProxy(approveProxy).claimTokens(token, from, to, amount);
    }

    function _getBalanceOf(address token) internal view returns(uint256) {
        return token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ? address(this).balance : IERC20Upgradeable(token).balanceOf(address(this));
    }

    function _approve(address token, address spender, uint256 amount) internal {
        if (IERC20Upgradeable(token).allowance(address(this), spender) == 0) {
            IERC20Upgradeable(token).safeApprove(spender, amount);
        } else {
            IERC20Upgradeable(token).safeApprove(spender, 0);
            IERC20Upgradeable(token).safeApprove(spender, amount);
        }
    }

    function _swapAndBridgeToInternal(SwapAndBridgeRequest calldata _request, bool improve) internal {
        require(_request.fromToken != address(0), "address 0");
        require(_request.toToken != address(0), "address 0");
        require(_request.fromToken != _request.toToken, "address equal");
        require(_request.to != address(0), "address 0");

        uint256 fromTokenBalance = _getBalanceOf(_request.fromToken);
        uint256 toTokenBalance = _getBalanceOf(_request.toToken);
        bool success;
        // 1. prepare and swap
        if (_request.fromToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            require(msg.value == _request.fromTokenAmount, "invalid amount");
            fromTokenBalance = fromTokenBalance - msg.value;
            (success, ) = dexRouter.call{value : msg.value}(_request.dexData);
        } else {
            require(msg.value == 0, "invalid msg value");
            if (improve) {
                payer = msg.sender;
                (success, ) = dexRouter.call(_request.dexData);
                payer = address(0);
            } else {
                _deposit(msg.sender, address(this), _request.fromToken, _request.fromTokenAmount);
                _approve(_request.fromToken, IApproveProxy(approveProxy).tokenApprove(), _request.fromTokenAmount);
                (success, ) = dexRouter.call(_request.dexData);
            }
        }

        // 2. check result and balance
        require(success, "dex router error");
        emit LogSwapAndBridgeTo(
            _request.adaptorId,
            msg.sender,
            _request.to,
            _request.fromToken,
            _request.fromTokenAmount - fromTokenBalance, // fromToken consumed
            _request.toToken,
            toTokenBalance
        );
    }

    //-------------------------------
    //------- Admin functions -------
    //-------------------------------
    function setApproveProxy(address _newApproveProxy) external onlyOwner {
        require(_newApproveProxy != address(0), "address 0");
        approveProxy = _newApproveProxy;
        emit ApproveProxyChanged(_newApproveProxy);
    }

    function setDexRouter(address _newDexRouter) external onlyOwner {
        require(_newDexRouter != address(0), "address 0");
        dexRouter = _newDexRouter;
        emit DexRouterChanged(_newDexRouter);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //-------------------------------
    //------- Users Functions -------
    //-------------------------------
    function swapAndBridgeTo(SwapAndBridgeRequest calldata _request) external payable nonReentrant whenNotPaused {
        _swapAndBridgeToInternal(_request, false);
    }

    function swapAndBridgeToImprove(SwapAndBridgeRequest calldata _request) external payable nonReentrant whenNotPaused {
        _swapAndBridgeToInternal(_request, true);
    }

    receive() external payable {}
}

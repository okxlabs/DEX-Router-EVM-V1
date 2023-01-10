// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IApproveProxy.sol";
import "../libraries/RevertReasonParser.sol";

/// @title XBridge
/// @notice Entrance for Bridge
/// @dev Entrance for Bridge
contract MockXBridge is
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct SwapBridgeRequestV2 {
        address fromToken; // the source token
        address toToken; // the token to be bridged
        address to; // the address to be bridged to
        uint256 adaptorId;
        uint256 toChainId;
        uint256 fromTokenAmount; // the source token amount
        uint256 toTokenMinAmount;
        uint256 toChainToTokenMinAmount;
        bytes data;
        bytes dexData; // the call data for dexRouter
        bytes extData;
    }

    struct SwapRequest {
        address fromToken;
        address toToken;
        address to;
        uint256 amount; // amount of swapped fromToken
        uint256 gasFeeAmount; // tx gas fee slash from fromToken
        uint256 srcChainId;
        bytes32 srcTxHash;
        bytes dexData;
        bytes extData;
    }

    address public constant NATIVE_TOKEN =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    //-------------------------------
    //------- storage ---------------
    //-------------------------------
    mapping(uint256 => address) public adaptorInfo;

    address public approveProxy;

    address public dexRouter;

    address public payer; // temp msg.sender when swap

    address public receiver;

    address public feeTo;

    address public admin;

    mapping(address => bool) public mpc;

    mapping(uint256 => mapping(bytes32 => bool)) public paidTx;

    mapping(uint256 => mapping(bytes32 => bool)) public receiveGasTx;

    // initialize
    function initialize() public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        admin = msg.sender;
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
    event Claimed(
        address to,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 toTokenAmount,
        uint256 gasFeeAmount,
        bytes32[] ext
    );

    //-------------------------------
    //------- Modifier --------------
    //-------------------------------
    modifier onlyMPC() {
        require(mpc[msg.sender], "only mpc");
        _;
    }

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

    function _getBalanceOf(address token) internal view returns (uint256) {
        return
            token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
                ? address(this).balance
                : IERC20Upgradeable(token).balanceOf(address(this));
    }

    function _getBalanceOf(address token, address who)
        internal
        view
        returns (uint256)
    {
        return
            token == NATIVE_TOKEN
                ? who.balance
                : IERC20Upgradeable(token).balanceOf(who);
    }

    function _approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20Upgradeable(token).allowance(address(this), spender) == 0) {
            IERC20Upgradeable(token).safeApprove(spender, amount);
        } else {
            IERC20Upgradeable(token).safeApprove(spender, 0);
            IERC20Upgradeable(token).safeApprove(spender, amount);
        }
    }

    function _transferToken(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == NATIVE_TOKEN) {
                payable(to).transfer(amount);
            } else {
                IERC20Upgradeable(token).safeTransfer(to, amount);
            }
        }
    }

    function _swapAndBridgeToInternal(SwapBridgeRequestV2 calldata _request) internal {
        require(_request.fromToken != address(0), "address 0");
        require(_request.toToken != address(0), "address 0");
        require(_request.fromToken != _request.toToken, "address equal");
        require(_request.to != address(0), "address 0");

        uint256 fromTokenBalance = _getBalanceOf(_request.fromToken);
        uint256 toTokenBalance = _getBalanceOf(_request.toToken);
        bool success;
        bytes memory result;
        bytes4 selectorId = bytes4(_request.dexData);
        require(selectorId == 0xd6576868 || selectorId == 0xe051c6e8 || selectorId == 0x1e00140d || selectorId == 0xd1b260d4 || selectorId == 0x9989d481, "selector id error");
        payer = msg.sender;
        receiver = address(this);
        // 1. prepare and swap
        if (_request.fromToken == NATIVE_TOKEN) {
            require(msg.value == _request.fromTokenAmount, "invalid amount");
            fromTokenBalance = fromTokenBalance - msg.value;
            (success, ) = dexRouter.call{value: msg.value}(_request.dexData);
        } else {
            require(msg.value == 0, "invalid msg value");
            (success, result) = dexRouter.call(_request.dexData);
        }
        delete payer;
        delete receiver;
        // 2. check result and balance
        require(success, RevertReasonParser.parse(result, ""));
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

    function claim(SwapRequest memory _request)
        public
        nonReentrant
        whenNotPaused
        onlyMPC
    {
        uint256 fromTokenOriginBalance = _getBalanceOf(_request.fromToken);
        uint256 fromTokenNeed = _request.amount + _request.gasFeeAmount;
        require(fromTokenOriginBalance >= fromTokenNeed, "no enough money");
        require(dexRouter != address(0), "address 0");
        require(!paidTx[_request.srcChainId][_request.srcTxHash], "has paid");
        paidTx[_request.srcChainId][_request.srcTxHash] = true;
        bytes32[] memory ext = new bytes32[](1);
        ext[0] = _request.srcTxHash;
        bool success;
        bytes memory result;
        // 1. gas fee
        _transferToken(feeTo, _request.fromToken, _request.gasFeeAmount);

        // 2. swap or transfer token to user
        if (_request.dexData.length > 0) {
            // swap
            payer = address(this);
            receiver = _request.to;
            uint256 toTokenReceiverBalance = _getBalanceOf(
                _request.toToken,
                receiver
            );
            if (_request.fromToken == NATIVE_TOKEN) {
                (success, result) = dexRouter.call{value: _request.amount}(
                    _request.dexData
                );
            } else {
                _approve(
                    _request.fromToken,
                    IApproveProxy(approveProxy).tokenApprove(),
                    _request.amount
                );
                (success, result) = dexRouter.call(_request.dexData);
            }
            toTokenReceiverBalance =
                _getBalanceOf(_request.toToken, receiver) -
                toTokenReceiverBalance;
            delete payer; // payer = 0;
            delete receiver; // receiver = 0;
            if (!success) {
                // transfer fromToken if swap failed
                _transferToken(
                    _request.to,
                    _request.fromToken,
                    _request.amount
                );
                emit Claimed(
                    _request.to,
                    _request.fromToken,
                    _request.toToken,
                    _request.amount,
                    0,
                    _request.gasFeeAmount,
                    ext
                );
            } else {
                emit Claimed(
                    _request.to,
                    _request.fromToken,
                    _request.toToken,
                    0,
                    toTokenReceiverBalance,
                    _request.gasFeeAmount,
                    ext
                );
            }
        } else {
            // transfer token
            _transferToken(_request.to, _request.fromToken, _request.amount);
            emit Claimed(
                _request.to,
                _request.fromToken,
                _request.toToken,
                _request.amount,
                0,
                _request.gasFeeAmount,
                ext
            );
        }

        // 3. check balance
        require(
            fromTokenOriginBalance - _getBalanceOf(_request.fromToken) <=
                fromTokenNeed,
            "slash much too money"
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

    function setFeeTo(address _newFeeTo) external onlyOwner {
        require(_newFeeTo != address(0), "feeTo address 0");
        feeTo = _newFeeTo;
        //emit FeeToChanged(_newFeeTo);
    }

    function setMpc(address[] memory _mpcList, bool[] memory _v) external onlyOwner {
        require(_mpcList.length == _v.length, "LENGTH_NOT_EQUAL");
        for (uint256 i = 0; i < _mpcList.length; i++) {
            mpc[_mpcList[i]] = _v[i];
        }
    }


    //-------------------------------
    //------- Users Functions -------
    //-------------------------------
    function swapBridgeToV2(SwapBridgeRequestV2 calldata _request) external payable nonReentrant whenNotPaused {
        _swapAndBridgeToInternal(_request);
    }

    function payerReceiver() external view returns (address, address) {
        return (payer, receiver);
    }

    receive() external payable {}
}

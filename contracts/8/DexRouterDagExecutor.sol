// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IWETH.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IWNativeRelayer.sol";

import "./libraries/EthReceiver.sol";
import "./libraries/CommonUtils.sol";
import "./libraries/UniversalERC20.sol";

/// @title DexRouterDagExecutor
/// @notice Executor of DexRouter DAG router paths
/// @dev As a router executor, this contract receives all the potential input tokens, executes the router paths, validates
/// the minReturnAmount and return the to token to receiver eventually. Since the router paths are passed in as a DAG and
// the token amounts are get from the balance of node tokens, the executor supports the multi input token swap natively.
contract DexRouterDagExecutor is
    CommonUtils,
    EthReceiver
{
    string public constant version = "v1.0.0-dag";
    using UniversalERC20 for IERC20;

    /// @notice Legacy support structure for backward compatibility
    /// @dev Contains basic swap request parameters
    struct BaseRequest {
        /// @notice Source token address encoded as uint256
        uint256 fromToken;
        /// @notice Destination token address
        address toToken;
        /// @notice Amount of source token to swap
        uint256 fromTokenAmount;
        /// @notice Minimum amount of destination token expected
        uint256 minReturnAmount;
        /// @notice Deadline timestamp for the swap
        uint256 deadLine;
    }

    /// @notice Structure representing a single routing path in the DAG
    /// @dev Contains all necessary information for executing a swap through an adapter
    struct RouterPath {
        /// @notice Address of the adapter contract to use for this swap
        address mixAdapter;
        /// @notice Address to receive the swapped tokens
        address assetTo;
        /// @notice Packed data containing: reverse flag (1 bit) | input node index (8 bits) | output node index (8 bits) | weight (16 bits) | pool address (20 bytes)
        uint256 rawData;
        /// @notice Additional data required by the adapter
        bytes extraData;
        /// @notice Source token address encoded as uint256
        uint256 fromToken;
    }

    /// @notice Core DAG algorithm data structure
    /// @dev Maintains the state of the DAG during execution
    struct SwapState {
        /// @notice the number of nodes need to be processed
        uint256 nodeNum;
        /// @notice node index -> token address, to record the token address of each node
        address[] nodeTokens;
        /// @notice node index -> processed flag, to record the processed status of each node
        bool[] processed;
        /// @notice node index -> noTransfer flag, to identify whether need to transfer token to assetTo when execute the node
        bool[] noTransfer;
        /// @notice node index -> assetTo address, to record the assetTo address of each node which only has one output edge
        address[] assetTo;
    }

    //-------------------------------
    //------- Modifier --------------
    //-------------------------------
    /// @notice Ensures a function is called before a specified deadline.
    /// @param deadLine The UNIX timestamp deadline.
    modifier isExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "Route: expired");
        _;
    }

    //-------------------------------
    //------- Internal Functions ----
    //-------------------------------
    /// @notice Initializes the swap state for the DAG execution
    /// @param _nodeNum The number of nodes in the DAG
    /// @return state The initialized swap state
    function _initSwapState(
        uint256 _nodeNum
    ) private pure returns (SwapState memory state) {
        state.nodeNum = _nodeNum;
        state.nodeTokens = new address[](_nodeNum);
        state.processed = new bool[](_nodeNum);
        state.noTransfer = new bool[](_nodeNum);
        state.assetTo = new address[](_nodeNum);
    }

    /// @notice Executes a swap through an adapter contract
    /// @param path RouterPath struct containing adapter, to, and extra data
    /// @param to Address to receive the swapped tokens
    /// @param refundTo Address to receive refunded tokens
    /// @dev Makes a low-level call to the adapter with encoded parameters
    function _exeAdapter(
        RouterPath memory path,
        address to,
        address refundTo
    ) private {
        bool reverse;
        address poolAddress;
        uint256 rawData = path.rawData;
        assembly {
            poolAddress := and(rawData, _ADDRESS_MASK)
            reverse := and(rawData, _REVERSE_MASK)
        }

        if (reverse) {
            (bool s, bytes memory res) = address(path.mixAdapter).call(
                abi.encodePacked(
                    abi.encodeWithSelector(
                        IAdapter.sellQuote.selector,
                        to,
                        poolAddress,
                        path.extraData
                    ),
                    ORIGIN_PAYER + uint(uint160(refundTo))
                )
            );
            if (!s) {
                _revert(res);
            }
        } else {
            (bool s, bytes memory res) = address(path.mixAdapter).call(
                abi.encodePacked(
                    abi.encodeWithSelector(
                        IAdapter.sellBase.selector,
                        to,
                        poolAddress,
                        path.extraData
                    ),
                    ORIGIN_PAYER + uint(uint160(refundTo))
                )
            );
            if (!s) {
                _revert(res);
            }
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with "FailedCall".
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c64a1edb67b6e3f4a15cca8909c9482ad33a02b0/contracts/utils/Address.sol#L135-L149
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            assembly ("memory-safe") {
                revert(add(returndata, 0x20), mload(returndata))
            }
        } else {
            revert("adaptor call failed");
        }
    }

    /// @notice Executes a single node in the DAG
    /// @param receiver Address receiving the swapped tokens
    /// @param refundTo Address receiving the refunded tokens
    /// @param isToNative Whether the output should be native token
    /// @param paths Detailed routing information for executing the swap across different paths or protocols.
    /// @param state The current state of the DAG execution
    function _exeNode(
        address receiver,
        address refundTo,
        bool isToNative,
        RouterPath[] memory paths,
        SwapState memory state
    ) private {
        address fromToken = _bytes32ToAddress(paths[0].fromToken);
        uint256 nodeBalance = IERC20(fromToken).balanceOf(address(this));
        require(nodeBalance > 0, "node balance must be greater than 0");

        uint256 nodeInputIndex;
        uint256 totalWeight;
        for (uint256 i = 0; i < paths.length; i++) {
            bytes32 rawData = bytes32(paths[i].rawData);
            uint256 inputIndex;
            uint256 outputIndex;
            {
                uint256 weight;

                assembly {
                    weight := shr(160, and(rawData, _WEIGHT_MASK))
                    inputIndex := shr(184, and(rawData, _INPUT_INDEX_MASK))
                    outputIndex := shr(176, and(rawData, _OUTPUT_INDEX_MASK))
                }

                if (i == 0) {
                    nodeInputIndex = inputIndex;
                } else {
                    require(fromToken == _bytes32ToAddress(paths[i].fromToken), "node fromToken inconsistent");
                    require(inputIndex == nodeInputIndex, "node inputIndex inconsistent");
                    require(!state.processed[outputIndex], "output node processed");
                }
                require(inputIndex < outputIndex, "inputIndex gte outputIndex");
                require(inputIndex < state.nodeNum && outputIndex <= state.nodeNum, "node index out of range"); // @notice this also constraints that only one node has no output edge
                totalWeight += weight;
                if (i == paths.length - 1) {
                    require(
                        totalWeight <= 10_000,
                        "totalWeight can not exceed 10000 limit"
                    );
                }

                if (!state.noTransfer[inputIndex]) {
                    uint256 _fromTokenAmount = weight == 10_000
                        ? nodeBalance
                        : (nodeBalance * weight) / 10_000;
                    SafeERC20.safeTransfer(
                        IERC20(fromToken),
                        paths[i].assetTo,
                        _fromTokenAmount
                    );
                }
            }

            address to = address(this);
            if (outputIndex == state.nodeNum && !isToNative) {
                to = receiver;
            } else if (outputIndex < state.nodeNum && state.noTransfer[outputIndex]) {
                to = state.assetTo[outputIndex];
            }

            _exeAdapter(
                paths[i],
                to,
                refundTo
            );
        }
        require(!state.processed[nodeInputIndex], "input node processed");

        state.nodeTokens[nodeInputIndex] = fromToken;
        state.processed[nodeInputIndex] = true;
    }

    /// @notice The executor holds all the potential input tokens before _exeDagSwap.
    /// @param receiver Address receiving the swapped tokens
    /// @param refundTo Address receiving the refunded tokens
    /// @param isToNative Whether the output should be native token
    /// @param paths Detailed routing information for executing the swap across different paths or protocols.
    function _exeDagSwap(
        address receiver,
        address refundTo,
        bool isToNative,
        RouterPath[][] memory paths
    ) private {
        uint256 nodeNum = paths.length;
        SwapState memory state = _initSwapState(nodeNum);

        // init state.noTransfer, inputIndex consistency is guaranteed by _exeNode
        // noTransfer[i]==true means:
        // 1. when execute the input edge of node i, the to address need to be the assetTo of output edge of node i.
        // 2. when execute the output edge of node i, the token is no need to transfer to assetTo.
        uint256 inputIndex;
        bytes32 rawData;
        for (uint256 i = 0; i < nodeNum;) {
            // init state.noTransfer
            require(paths[i].length > 0, "paths must be greater than 0");
            rawData = bytes32(paths[i][0].rawData);
            assembly {
                inputIndex := shr(184, and(rawData, _INPUT_INDEX_MASK))
            }
            bool noTransfer = paths[i].length == 1;
            state.noTransfer[inputIndex] = noTransfer;
            if (noTransfer) {
                state.assetTo[inputIndex] = paths[i][0].assetTo;
            }

            // !!!notice: check paths[i].fromToken != paths[i+1].fromToken cann't resolve node balance conflict

            unchecked {
                ++i;
            }
        }

        // execute DAG swap
        for (uint256 i = 0; i < nodeNum;) {
            _exeNode(receiver, refundTo, isToNative, paths[i], state);

            unchecked {
                ++i;
            }
        }

        // ensure no tokens remain
        for (uint256 i = 0; i < nodeNum;) {
            require(
                state.nodeTokens[i] == address(0)
                    && IERC20(state.nodeTokens[i]).balanceOf(address(this)) == 0,
                "node token remains"
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Transfers the specified token to the user.
    /// @param token The address of the token to be transferred.
    /// @param to The address of the receiver.
    /// @dev Handles the withdrawal of tokens to the user, converting WETH to ETH if necessary.
    function _transferTokenToUser(address token, address to) private {
        if ((IERC20(token).isETH())) {
            uint256 wethBal = IERC20(address(uint160(_WETH))).balanceOf(
                address(this)
            );
            if (wethBal > 0) {
                IWETH(address(uint160(_WETH))).transfer(
                    _WNATIVE_RELAY,
                    wethBal
                );
                IWNativeRelayer(_WNATIVE_RELAY).withdraw(wethBal);
            }
            if (to != address(this)) {
                uint256 ethBal = address(this).balance;
                if (ethBal > 0) {
                    (bool success, ) = payable(to).call{value: ethBal}("");
                    require(success, "transfer native token failed");
                }
            }
        } else {
            if (to != address(this)) {
                uint256 bal = IERC20(token).balanceOf(address(this));
                if (bal > 0) {
                    SafeERC20.safeTransfer(IERC20(token), to, bal);
                }
            }
        }
    }

    /// @notice Converts a uint256 value into an address.
    /// @param param The uint256 value to be converted.
    /// @return result The address obtained from the conversion.
    /// @dev This function is used to extract an address from a uint256,
    /// typically used when dealing with low-level data operations or when addresses are packed into larger data types.
    function _bytes32ToAddress(
        uint256 param
    ) private pure returns (address result) {
        assembly {
            result := and(param, _ADDRESS_MASK)
        }
    }

    /// @notice Executes a complex swap based on provided parameters and paths.
    /// @param baseRequest Basic swap details including tokens, amounts, and deadline.
    /// @param paths Detailed swap paths for execution.
    /// @param refundTo Address receiving the refunded tokens.
    /// @param receiver Address receiving the swapped tokens.
    /// @return returnAmount Total received tokens from the swap.
    function _swapInternal(
        BaseRequest memory baseRequest,
        RouterPath[][] memory paths,
        address refundTo,
        address receiver
    ) private returns (uint256 returnAmount) {
        // transfer from token in
        BaseRequest memory _baseRequest = baseRequest;
        require(
            _baseRequest.fromTokenAmount > 0,
            "Route: fromTokenAmount must be > 0"
        );
        address fromToken = _bytes32ToAddress(_baseRequest.fromToken);
        uint256 fromTokenBalance = IERC20(fromToken).balanceOf(address(this));
        require(_baseRequest.fromTokenAmount >= fromTokenBalance, "fromTokenAmount must be >= fromTokenBalance");

        returnAmount = IERC20(_baseRequest.toToken).universalBalanceOf(
            receiver
        );

        // In order to deal with ETH/WETH transfer rules in a unified manner,
        // we do not need to judge according to fromToken.
        if (UniversalERC20.isETH(IERC20(fromToken))) {
            IWETH(address(uint160(_WETH))).deposit{
                value: _baseRequest.fromTokenAmount
            }();
        } else {
            require(msg.value == 0, "msg.value must be 0");
        }

        // execute DAG swap
        _exeDagSwap(receiver, refundTo, IERC20(_baseRequest.toToken).isETH(), paths);

        // transfer tokens to user, if the toToken is ETH, the WETH will be converted to ETH.
        _transferTokenToUser(_baseRequest.toToken, receiver);

        // check minReturnAmount
        returnAmount =
            IERC20(_baseRequest.toToken).universalBalanceOf(receiver) -
            returnAmount;
        require(
            returnAmount >= _baseRequest.minReturnAmount,
            "Min return not reached"
        );

        emit OrderRecord(
            fromToken,
            _baseRequest.toToken,
            tx.origin,
            _baseRequest.fromTokenAmount,
            returnAmount
        );
        return returnAmount;
    }

    //-------------------------------
    //------- Users Functions -------
    //-------------------------------
    /// @notice Executes DAG swap router paths. As a router executor, this function only executes the DAG swap and does not handle the commission.
    /// @param receiver Address receiving the swapped tokens.
    /// @param refundTo Address receiving the refunded tokens.
    /// @param baseRequest Basic swap details including tokens, amounts, and deadline.
    /// @param paths Detailed routing information for executing the swap across different paths or protocols.
    /// @return returnAmount The total amount of destination tokens received from the swap.
    function swapTo(
        address receiver,
        address refundTo,
        BaseRequest calldata baseRequest,
        RouterPath[][] calldata paths
    )
        external
        payable
        isExpired(baseRequest.deadLine)
        returns (uint256 returnAmount)
    {
        return _swapInternal(baseRequest, paths, refundTo, receiver);
    }
}

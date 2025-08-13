// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libraries/CommonLib.sol";
import "./libraries/UniversalERC20.sol";
import "./interfaces/IERC20.sol";

abstract contract DagRouter is CommonLib {

    using UniversalERC20 for IERC20;

    /// @notice Core DAG algorithm data structure
    /// @dev Maintains the state of the DAG during execution
    struct SwapState {
        /// @notice the number of nodes need to be processed
        uint256 nodeNum;
        /// @notice node index -> processed flag, to record the processed status of each node
        bool[] processed;
        /// @notice node index -> onlyOneOutput flag, to identify whether the node has only one output edge
        bool[] onlyOneOutput;
        /// @notice node index -> assetTo address, to record the assetTo address of each node which only has one output edge
        address[] assetTo;
        /// @notice to record the accumulated amount of the each node
        uint256 accAmount;
        /// @notice to record the refundTo address of the DAG
        address refundTo;
    }

    function _dagSwapInternal(
        BaseRequest calldata baseRequest,
        RouterPath[] calldata paths,
        address payer,
        address refundTo,
        address receiver
    ) internal returns (uint256 returnAmount) {
        // 1. transfer from token in
        BaseRequest memory _baseRequest = baseRequest;
        require(
            _baseRequest.fromTokenAmount > 0,
            "fromTokenAmount must be > 0"
        );
        address fromToken = _bytes32ToAddress(_baseRequest.fromToken);
        returnAmount = IERC20(_baseRequest.toToken).universalBalanceOf(
            receiver
        );

        // In order to deal with ETH/WETH transfer rules in a unified manner,
        // we do not need to judge according to fromToken.
        if (UniversalERC20.isETH(IERC20(fromToken))) {
            IWETH(address(uint160(_WETH))).deposit{
                value: _baseRequest.fromTokenAmount
            }();
            payer = address(this);
        }

        // 2. check and execute dag swap
        {
            require(paths.length > 0, "paths must be > 0");
            address firstNodeToken = _bytes32ToAddress(paths[0].fromToken);
            require(fromToken == firstNodeToken || (fromToken == _ETH && firstNodeToken == _WETH), "fromToken mismatch");
            uint256 firstNodeIndex = paths[0].rawData[0];
            assembly {
                firstNodeIndex := shr(184, and(firstNodeIndex, _INPUT_INDEX_MASK))
            }
            require(firstNodeIndex == 0, "first node index must be 0");
        }
        _exeDagSwap(payer, receiver, refundTo, _baseRequest.fromTokenAmount, IERC20(_baseRequest.toToken).isETH(), paths);

        // 3. transfer tokens to receiver
        _transferTokenToUser(_baseRequest.toToken, receiver);

        // 4. check minReturnAmount
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
            msg.sender,
            _baseRequest.fromTokenAmount,
            returnAmount
        );

        return returnAmount;
    }

    function _exeDagSwap(
        address payer,
        address receiver,
        address refundTo,
        uint256 firstNodeBalance,
        bool isToNative,
        RouterPath[] calldata paths
    ) private {
        uint256 nodeNum = paths.length;
        SwapState memory swapState = _initSwapState(nodeNum, refundTo);

        // Init swapState.onlyOneOutput and swapState.assetTo
        // swapState.onlyOneOutput[i]==true means:
        // 1. when execute the input edge of node i, the to address need to be the assetTo of output edge of node i (if node i is not the last node).
        // 2. when execute the output edge of node i, the token is no need to transfer to assetTo (if node i is not the first node).
        for (uint256 i = 0; i < nodeNum; ) {
            bytes32 rawData = bytes32(paths[i].rawData[0]);
            uint256 inputIndex;
            assembly {
                inputIndex := shr(184, and(rawData, _INPUT_INDEX_MASK))
            }

            bool onlyOneOutput = paths[i].mixAdapters.length == 1;
            swapState.onlyOneOutput[inputIndex] = onlyOneOutput;
            if (onlyOneOutput) {
                swapState.assetTo[inputIndex] = paths[i].assetTo[0];
            }
            
            unchecked {
                ++i;
            }
        }

        // execute nodes
        uint256 nodeBalance = firstNodeBalance;
        for (uint256 i = 0; i < nodeNum;) {
            _exeNode(payer, receiver, nodeBalance, isToNative, paths[i], swapState);
            payer = address(this); // payer need to be reset to address(this) for non-first node
            nodeBalance = 0; // nodeBalance is need to be reset to 0 for non-first node

            unchecked {
                ++i;
            }
        }

        // ensure no token residue
        for (uint256 i = 0; i < nodeNum;) {
            address token = _bytes32ToAddress(paths[i].fromToken);
            require(IERC20(token).balanceOf(address(this)) == 0, "token remains");

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Initializes the swap state for the DAG execution
    /// @param _nodeNum The number of nodes in the DAG
    /// @param _refundTo The refundTo address of the DAG
    /// @return state The initialized swap state
    function _initSwapState(
        uint256 _nodeNum,
        address _refundTo
    ) private pure returns (SwapState memory state) {
        state.nodeNum = _nodeNum;
        state.processed = new bool[](_nodeNum + 1);
        state.onlyOneOutput = new bool[](_nodeNum);
        state.assetTo = new address[](_nodeNum);
        state.refundTo = _refundTo;
    }

    function _exeNode(
        address payer,
        address receiver,
        uint256 nodeBalance,
        bool isToNative,
        RouterPath calldata path,
        SwapState memory swapState
    ) private {
        uint256 nodeIndex;
        uint256 totalWeight;
        swapState.accAmount = 0;
        address fromToken = _bytes32ToAddress(path.fromToken);
        require(path.mixAdapters.length > 0, "edge length must be > 0");
        require(
            path.mixAdapters.length == path.rawData.length &&
            path.mixAdapters.length == path.extraData.length &&
            path.mixAdapters.length == path.assetTo.length,
            "path length mismatch"
        );
        for (uint256 i = 0; i < path.mixAdapters.length;) {
            uint256 inputIndex;
            uint256 outputIndex;
            uint256 weight;
            {
                bytes32 rawData = bytes32(path.rawData[i]);

                assembly {
                    weight := shr(160, and(rawData, _WEIGHT_MASK))
                    inputIndex := shr(184, and(rawData, _INPUT_INDEX_MASK))
                    outputIndex := shr(176, and(rawData, _OUTPUT_INDEX_MASK))
                }

                // check dag consistency
                if (i == 0) {
                    nodeIndex = inputIndex;
                } else {
                    require(inputIndex == nodeIndex, "node inputIndex inconsistent");
                }
                require(!swapState.processed[outputIndex], "node processed");
                require(inputIndex < outputIndex, "inputIndex gte outputIndex");
                require(outputIndex <= swapState.nodeNum, "node index out of range"); // this also constraints that only one node has no output edge
                totalWeight += weight;
                if (i == path.mixAdapters.length - 1) {
                    require(
                        totalWeight == 10_000,
                        "totalWeight must be 10000"
                    );
                }
            }

            {
                // For the first node, the nodeBalance passed in is non-zero, so don't need to get nodeBalance with balanceOf function,
                // For the non-first node, the nodeBalance passed in is zero, so when onlyOneOutput is true, need to get nodeBalance with
                // balanceOf function for the first edge.
                bool needTransfer = nodeIndex == 0 || !swapState.onlyOneOutput[nodeIndex];
                if (nodeBalance == 0 && needTransfer && i == 0) {
                    nodeBalance = IERC20(fromToken).balanceOf(address(this));
                    require(nodeBalance > 0, "node balance eq 0");
                }

                if (needTransfer) {
                    uint256 _fromTokenAmount;
                    if (i == path.mixAdapters.length - 1) {
                        _fromTokenAmount = nodeBalance - swapState.accAmount;
                    } else {
                        _fromTokenAmount = weight == 10_000
                            ? nodeBalance
                            : (nodeBalance * weight) / 10_000;
                        swapState.accAmount += _fromTokenAmount;
                    }
                     _transferInternal(
                        payer,
                        path.assetTo[i],
                        fromToken,
                        _fromTokenAmount
                    );
                }
            }

            address to = address(this);
            if (outputIndex < swapState.nodeNum && swapState.onlyOneOutput[outputIndex]) {
                to = swapState.assetTo[outputIndex];
            } else if (outputIndex == swapState.nodeNum && !isToNative) {
                to = receiver;
            }

            _exeEdge(
                path.rawData[i],
                path.mixAdapters[i],
                path.extraData[i],
                to,
                swapState.refundTo
            );

            unchecked {
                ++i;
            }
        }
        require(!swapState.processed[nodeIndex], "input node processed");

        swapState.processed[nodeIndex] = true;
    }

    function _exeEdge(
        uint256 rawData,
        address mixAdapter,
        bytes memory extraData,
        address to,
        address refundTo
    ) private {
        bool reverse;
        address poolAddress;
        assembly {
            poolAddress := and(rawData, _ADDRESS_MASK)
            reverse := and(rawData, _REVERSE_MASK)
        }

        _exeAdapter(
            reverse,
            mixAdapter,
            to,
            poolAddress,
            extraData,
            refundTo
        );
    }
}
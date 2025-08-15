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
        /// @notice the refundTo address of the DAG
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

        require(paths.length > 0, "paths must be > 0");
        address firstNodeToken = _bytes32ToAddress(paths[0].fromToken);

        // In order to deal with ETH/WETH transfer rules in a unified manner,
        // we do not need to judge according to fromToken.
        if (IERC20(fromToken).isETH()) {
            require(firstNodeToken == _WETH, "firstToken mismatch");
            IWETH(address(uint160(_WETH))).deposit{
                value: _baseRequest.fromTokenAmount
            }();
            payer = address(this);
        } else {
            require(firstNodeToken == fromToken, "firstToken mismatch");
        }

        // 2. execute dag swap
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

    /// @notice The core logic to execute the DAG swap. For the first node, the payer should use passed value.
    /// For the non-first node, the payer should always be address(this) cause the to address of the middle swap is address(this).
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

        // execute nodes
        for (uint256 i = 0; i < nodeNum;) {
            if (i != 0) { // reset payer for non-first node
                payer = address(this);
            }

            _exeNode(payer, receiver, firstNodeBalance, i, isToNative, paths[i], swapState);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Initialize the swap state for the DAG execution
    function _initSwapState(
        uint256 _nodeNum,
        address _refundTo
    ) private pure returns (SwapState memory state) {
        state.nodeNum = _nodeNum;
        state.refundTo = _refundTo;
    }

    /// @notice The core logic to execute the each node
    function _exeNode(
        address payer,
        address receiver,
        uint256 nodeBalance,
        uint256 nodeIndex,
        bool isToNative,
        RouterPath calldata path,
        SwapState memory swapState
    ) private {
        uint256 totalWeight;
        uint256 accAmount;
        address fromToken = _bytes32ToAddress(path.fromToken);

        require(path.mixAdapters.length > 0, "edge length must be > 0");
        require(
            path.mixAdapters.length == path.rawData.length &&
            path.mixAdapters.length == path.extraData.length &&
            path.mixAdapters.length == path.assetTo.length,
            "path length mismatch"
        );

        // to get the nodeBalance for non-first node, the balance of the first node is the original passed value
        if (nodeIndex != 0) {
            nodeBalance = IERC20(fromToken).balanceOf(address(this));
            require(nodeBalance > 0, "node balance must be > 0");
        }

        // execute edges
        for (uint256 i = 0; i < path.mixAdapters.length;) {
            uint256 inputIndex;
            uint256 outputIndex;
            uint256 weight;

            // 1. get inputIndex, outputIndex, weight and verify
            {
                bytes32 rawData = bytes32(path.rawData[i]);
                assembly {
                    weight := shr(160, and(rawData, _WEIGHT_MASK))
                    inputIndex := shr(184, and(rawData, _INPUT_INDEX_MASK))
                    outputIndex := shr(176, and(rawData, _OUTPUT_INDEX_MASK))
                }

                require(inputIndex == nodeIndex, "node inputIndex inconsistent");
                require(inputIndex < outputIndex && outputIndex <= swapState.nodeNum, "node index out of range");

                totalWeight += weight;
                if (i == path.mixAdapters.length - 1) {
                    require(
                        totalWeight == 10_000,
                        "totalWeight must be 10000"
                    );
                }
            }

            // 2. transfer fromToken from payer to assetTo of edge
            {
                uint256 _fromTokenAmount;
                if (i == path.mixAdapters.length - 1) {
                    if (payer == address(this)) {
                        _fromTokenAmount = IERC20(fromToken).balanceOf(address(this));
                    } else {
                        _fromTokenAmount = nodeBalance - accAmount;
                    }
                } else {
                    _fromTokenAmount = (nodeBalance * weight) / 10_000;
                    accAmount += _fromTokenAmount;
                }
                _transferInternal(
                    payer,
                    path.assetTo[i],
                    fromToken,
                    _fromTokenAmount
                );
            }

            // 3. execute single swap
            {
                address to = address(this);
                if (outputIndex == swapState.nodeNum && !isToNative) {
                    to = receiver;
                }
                _exeEdge(
                    path.rawData[i],
                    path.mixAdapters[i],
                    path.extraData[i],
                    to,
                    swapState.refundTo
                );
            }

            unchecked {
                ++i;
            }
        }
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
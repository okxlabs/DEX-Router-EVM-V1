// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Adapter for Biswapv3 */
/* tstore / tload requires Cancun with solidity >=0.8.24 */

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IBiswapV3.sol";

contract BiAdapterV3 is IAdapter {
    using SafeERC20 for IERC20;
    //bytes32 constant keyPoolAddress = keccak256("BiAdapterV3.Pool.Address");
    address private _pool;

    event Received(address, uint256);

    /*
    function getAddress() internal view returns (address pool) {
        bytes32 value;
        bytes32 key = keyPoolAddress;
        assembly {
            value := tload(key)
        }
        pool = address(bytes20(value));
    }*/

    function swapX2YCallback(uint256, uint256, bytes calldata data) external {
        //address _pool = getAddress();
        require(msg.sender == _pool, "only pool can call swapX2YCallback");
        (address tokenX, uint256 amount) = abi.decode(data, (address, uint256));
        IERC20(tokenX).safeTransfer(_pool, amount);
    }

    function swapY2XCallback(uint256, uint256, bytes calldata data) external {
        //address _pool = getAddress();
        require(msg.sender == _pool, "only pool can call swapY2XCallback");
        (address tokenY, uint256 amount) = abi.decode(data, (address, uint256));
        IERC20(tokenY).safeTransfer(_pool, amount);
    }

    function _biswapV3(
        address to,
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 minAcquired
    ) private {
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 amountOut;
        if (tokenIn < tokenOut) {
            //tokenIn is x, tokenOut is y, swap x to y
            (, amountOut, ) = IBiswapV3(pool).swapX2Y(
                to,
                uint128(amountIn),
                -799999,
                abi.encode(tokenIn, amountIn)
            );
        } else {
            //tokenIn is y, tokenOut is x, swap y to x
            (amountOut, , ) = IBiswapV3(pool).swapY2X(
                to,
                uint128(amountIn),
                799999,
                abi.encode(tokenIn, amountIn)
            );
        }
        require(amountOut >= minAcquired, "amountOut shortfall");
    }

    // sell X for Y
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        /*
        bytes32 key = keyPoolAddress;
        bytes32 value = bytes32(bytes20(pool));

        assembly {
            if tload(key) {
                revert(0, 0)
            }
            tstore(key, value)
        }*/

        _pool = pool;
        (address tokenIn, address tokenOut, uint256 minAcquired) = abi.decode(
            moreInfo,
            (address, address, uint256)
        );
        _biswapV3(to, pool, tokenIn, tokenOut, minAcquired);
        _pool = address(0);

        /*
        assembly {
            tstore(key, 0)
        }*/
    }

    // sell Y for X
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        /*
        bytes32 key = keyPoolAddress;
        bytes32 value = bytes32(bytes20(pool));
        
        assembly {
            if tload(key) {
                revert(0, 0)
            }
            tstore(key, value)
        }*/

        _pool = pool;
        (address tokenIn, address tokenOut, uint256 minAcquired) = abi.decode(
            moreInfo,
            (address, address, uint256)
        );
        _biswapV3(to, pool, tokenIn, tokenOut, minAcquired);
        _pool = address(0);

        /*
        assembly {
            tstore(key, 0)
        }*/
    }

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IFirebird.sol";
import "../interfaces/IERC20.sol";

/// @title FirebirdAdapter
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract FirebirdAdapter is IAdapter {
    
    address public immutable FIREBIRD_FORMULA_ADDRESS;

    struct PoolData {
        uint256 reserveIn;
        uint256 reserveOut;
        uint32 tokenInWeight;
        uint32 tokenOutWeight;
        uint32 swapFee;
    }
    constructor(address _firebirdFormula) {
        FIREBIRD_FORMULA_ADDRESS = _firebirdFormula;
    }
    
    // fromToken == token0
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        PoolData memory poolData;
        address baseToken = IPair(pool).token0();
        (poolData.reserveIn, poolData.reserveOut, ) = IPair(pool).getReserves();
        (poolData.tokenInWeight, poolData.tokenOutWeight) = IPair(pool).getTokenWeights();
        (poolData.swapFee) = abi.decode( moreInfo, (uint32));
        require(
            poolData.reserveIn > 0 && poolData.reserveOut > 0,
            "FirebirdAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - poolData.reserveIn;

        if (poolData.tokenInWeight == poolData.tokenOutWeight) {
            uint256 sellBaseAmountWithFee = sellBaseAmount * (10000 - poolData.swapFee);
            uint256 receiveQuoteAmount = sellBaseAmountWithFee * poolData.reserveOut / (poolData.reserveIn * 10000 + sellBaseAmountWithFee);
            IPair(pool).swap(0, receiveQuoteAmount, to, new bytes(0));
        }else{
            uint256 amountOut = IFireBirdFormula(FIREBIRD_FORMULA_ADDRESS).getAmountOut(
                sellBaseAmount,
                poolData.reserveIn,
                poolData.reserveOut,
                poolData.tokenInWeight,
                poolData.tokenOutWeight,
                poolData.swapFee
            );
            IPair(pool).swap(0, amountOut, to, new bytes(0));
        }
    }

    // fromToken == token1
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        PoolData memory poolData;
        address quoteToken = IPair(pool).token1();
        (poolData.reserveOut, poolData.reserveIn, ) = IPair(pool).getReserves();
        (poolData.tokenOutWeight, poolData.tokenInWeight) = IPair(pool).getTokenWeights();
        (poolData.swapFee) = abi.decode( moreInfo, (uint32));
        require(
            poolData.reserveIn > 0 && poolData.reserveOut > 0,
            "FirebirdAdapter: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance1 = IERC20(quoteToken).balanceOf(pool);
        uint256 sellQuoteAmount = balance1 - poolData.reserveIn;

        if (poolData.tokenInWeight == poolData.tokenOutWeight) {
            uint256 sellQuoteAmountWithFee = sellQuoteAmount * (10000 - poolData.swapFee);
            uint256 receiveBaseAmount = sellQuoteAmountWithFee * poolData.reserveOut / (poolData.reserveIn * 10000 + sellQuoteAmountWithFee);
            IPair(pool).swap(receiveBaseAmount, 0, to, new bytes(0));
        }else{
            uint256 amountOut = IFireBirdFormula(FIREBIRD_FORMULA_ADDRESS).getAmountOut(
                sellQuoteAmount,
                poolData.reserveIn,
                poolData.reserveOut,
                poolData.tokenInWeight,
                poolData.tokenOutWeight,
                poolData.swapFee
            );
            IPair(pool).swap(amountOut, 0, to, new bytes(0));
        }
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library Structs {
    struct CollateralReserves {
        uint256 token0RealReserves;
        uint256 token1RealReserves;
        uint256 token0ImaginaryReserves;
        uint256 token1ImaginaryReserves;
    }

    struct ConstantViews {
        uint256 dexId;
        address liquidity;
        address factory;
        Implementations implementations;
        address deployerContract;
        address token0;
        address token1;
        bytes32 supplyToken0Slot;
        bytes32 borrowToken0Slot;
        bytes32 supplyToken1Slot;
        bytes32 borrowToken1Slot;
        bytes32 exchangePriceToken0Slot;
        bytes32 exchangePriceToken1Slot;
        uint256 oracleMapping;
    }

    struct ConstantViews2 {
        uint256 token0NumeratorPrecision;
        uint256 token0DenominatorPrecision;
        uint256 token1NumeratorPrecision;
        uint256 token1DenominatorPrecision;
    }

    struct DebtReserves {
        uint256 token0Debt;
        uint256 token1Debt;
        uint256 token0RealReserves;
        uint256 token1RealReserves;
        uint256 token0ImaginaryReserves;
        uint256 token1ImaginaryReserves;
    }

    struct Implementations {
        address shift;
        address admin;
        address colOperations;
        address debtOperations;
        address perfectOperationsAndSwapOut;
    }

    struct Oracle {
        uint256 twap1by0;
        uint256 lowestPrice1by0;
        uint256 highestPrice1by0;
        uint256 twap0by1;
        uint256 lowestPrice0by1;
        uint256 highestPrice0by1;
    }

    struct PricesAndExchangePrice {
        uint256 lastStoredPrice;
        uint256 centerPrice;
        uint256 upperRange;
        uint256 lowerRange;
        uint256 geometricMean;
        uint256 supplyToken0ExchangePrice;
        uint256 borrowToken0ExchangePrice;
        uint256 supplyToken1ExchangePrice;
        uint256 borrowToken1ExchangePrice;
    }
}

interface IFluidDex {
    error FluidDexError(uint256 errorId_);
    error FluidDexFactoryError(uint256 errorId);
    error FluidDexLiquidityOutput(uint256 shares_);
    error FluidDexPerfectLiquidityOutput(uint256 token0Amt, uint256 token1Amt);
    error FluidDexPricesAndExchangeRates(Structs.PricesAndExchangePrice pex_);
    error FluidDexSingleTokenOutput(uint256 tokenAmt);
    error FluidDexSwapResult(uint256 amountOut);
    error FluidLiquidityCalcsError(uint256 errorId_);
    error FluidSafeTransferError(uint256 errorId_);

    event LogArbitrage(int256 routing, uint256 amtOut);
    event LogBorrowDebtLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    event LogBorrowPerfectDebtLiquidity(
        uint256 shares,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event LogDepositColLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    event LogDepositPerfectColLiquidity(
        uint256 shares,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event LogPaybackDebtInOneToken(
        uint256 shares,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event LogPaybackDebtLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    event LogPaybackPerfectDebtLiquidity(
        uint256 shares,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event LogWithdrawColInOneToken(
        uint256 shares,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event LogWithdrawColLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    );
    event LogWithdrawPerfectColLiquidity(
        uint256 shares,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event Swap(bool swap0to1, uint256 amountIn, uint256 amountOut, address to);

    function DEX_ID() external view returns (uint256);
    function borrow(
        uint256 token0Amt_,
        uint256 token1Amt_,
        uint256 maxSharesAmt_,
        address to_
    ) external returns (uint256 shares_);
    function borrowPerfect(
        uint256 shares_,
        uint256 minToken0Borrow_,
        uint256 minToken1Borrow_,
        address to_
    ) external returns (uint256 token0Amt_, uint256 token1Amt_);
    function constantsView()
        external
        view
        returns (Structs.ConstantViews memory constantsView_);
    function constantsView2()
        external
        view
        returns (Structs.ConstantViews2 memory constantsView2_);
    function deposit(
        uint256 token0Amt_,
        uint256 token1Amt_,
        uint256 minSharesAmt_,
        bool estimate_
    ) external payable returns (uint256 shares_);
    function depositPerfect(
        uint256 shares_,
        uint256 maxToken0Deposit_,
        uint256 maxToken1Deposit_,
        bool estimate_
    ) external payable returns (uint256 token0Amt_, uint256 token1Amt_);
    function getCollateralReserves(
        uint256 geometricMean_,
        uint256 upperRange_,
        uint256 lowerRange_,
        uint256 token0SupplyExchangePrice_,
        uint256 token1SupplyExchangePrice_
    ) external view returns (Structs.CollateralReserves memory c_);
    function getDebtReserves(
        uint256 geometricMean_,
        uint256 upperRange_,
        uint256 lowerRange_,
        uint256 token0BorrowExchangePrice_,
        uint256 token1BorrowExchangePrice_
    ) external view returns (Structs.DebtReserves memory d_);
    function getPricesAndExchangePrices() external;
    function liquidityCallback(
        address token_,
        uint256 amount_,
        bytes memory data_
    ) external;
    function oraclePrice(
        uint256[] memory secondsAgos_
    )
        external
        view
        returns (Structs.Oracle[] memory twaps_, uint256 currentPrice_);
    function payback(
        uint256 token0Amt_,
        uint256 token1Amt_,
        uint256 minSharesAmt_,
        bool estimate_
    ) external payable returns (uint256 shares_);
    function paybackPerfect(
        uint256 shares_,
        uint256 maxToken0Payback_,
        uint256 maxToken1Payback_,
        bool estimate_
    ) external payable returns (uint256 token0Amt_, uint256 token1Amt_);
    function paybackPerfectInOneToken(
        uint256 shares_,
        uint256 maxToken0_,
        uint256 maxToken1_,
        bool estimate_
    ) external payable returns (uint256 paybackAmt_);
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
    function swapIn(
        bool swap0to1_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address to_
    ) external payable returns (uint256 amountOut_);
    function swapInWithCallback(
        bool swap0to1_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address to_
    ) external payable returns (uint256 amountOut_);
    function swapOut(
        bool swap0to1_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address to_
    ) external payable returns (uint256 amountIn_);
    function swapOutWithCallback(
        bool swap0to1_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address to_
    ) external payable returns (uint256 amountIn_);
    function withdraw(
        uint256 token0Amt_,
        uint256 token1Amt_,
        uint256 maxSharesAmt_,
        address to_
    ) external returns (uint256 shares_);
    function withdrawPerfect(
        uint256 shares_,
        uint256 minToken0Withdraw_,
        uint256 minToken1Withdraw_,
        address to_
    ) external returns (uint256 token0Amt_, uint256 token1Amt_);
    function withdrawPerfectInOneToken(
        uint256 shares_,
        uint256 minToken0_,
        uint256 minToken1_,
        address to_
    ) external returns (uint256 withdrawAmt_);
}

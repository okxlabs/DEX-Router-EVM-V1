pragma solidity ^0.8.0;

// restricted liquidity lib for adapter developer
library RestrictedLiquidityLib {

    // if dex is restricted liquidity, then must use this struct to build more info
    struct TradeInfo {
        address fundAddress; // fromTokenAddress
        address tokenAddress; // toTokenAddress
        bool buyMeme;
        uint256 sellMemeAmount;
        uint256 sellCommissionRate1;
        address sellCommissionReceiver1;
        uint256 sellCommissionRate2;
        address sellCommissionReceiver2;
        uint256 minReturnAmount;
    }

}

// refund lib for adapter developer
library RefundLib {
    uint256 private constant ORIGIN_PAYER = 0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    function getPayerOrigin() internal pure returns (address payerOriginAddr) {
        uint256 _payerOrigin;
        // solhint-disable-next-line no-inline-assembly
        // This assembly is necessary to access calldata size and load data from specific positions
        // which cannot be achieved with pure Solidity code
        assembly {
            // Get the total size of the calldata
            let size := calldatasize()
            // Load the last 32 bytes of the calldata, which is assumed to contain the payer origin
            // Assumption: The calldata is structured such that the payer origin is always at the end
            _payerOrigin := calldataload(sub(size, 32))
        }
        if ((_payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
            payerOriginAddr = address(uint160(uint256(_payerOrigin) & ADDRESS_MASK));
        }
    }
}
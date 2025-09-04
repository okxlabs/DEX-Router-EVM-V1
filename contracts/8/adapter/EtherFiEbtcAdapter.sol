// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITellerWithMultiAssetSupport.sol";
import "../libraries/SafeERC20.sol";

contract EtherFiEbtcAdapter is IAdapter {
    using SafeERC20 for IERC20;

    address public immutable TELLER;
    address public immutable EBTC;

    constructor(address _teller, address _ebtc) {
        TELLER = _teller;
        EBTC = _ebtc;
    }

    // token -> eBTC (deposit token to get eBTC)
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        // Get input token from the moreInfo
        IERC20 depositToken = IERC20(abi.decode(moreInfo, (address)));
        uint256 amount = depositToken.balanceOf(address(this));
        
        // Approve EBTC to spend our tokens
        SafeERC20.safeApprove(depositToken, EBTC, amount);
        
        // Deposit token to get eBTC shares
        ITellerWithMultiAssetSupport(TELLER).deposit(
            depositToken,
            amount,
            0 // minimumMint
        );

        // Transfer eBTC to recipient if not this contract
        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(EBTC),
                to,
                IERC20(EBTC).balanceOf(address(this))
            );
        }
    }

    // Not implemented as this adapter only supports one-way conversion
    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        revert("eBTC withdraw not supported");
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IArenaTokenManager.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract ArenaAdapter is IAdapter {
    uint256 internal constant ORIGIN_PAYER =
        0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000;
    address public immutable WNATIVETOKEN;

    event Received(address sender, uint256 amount);

    constructor(address payable wNativeToken) {
        WNATIVETOKEN = wNativeToken;
    }

    // fromToken == WNativeToken, toToken == MemeToken
    function sellBase(
        address to,
        address pool, // BondingCurve contract, TokenManager
        bytes memory moreInfo
    ) external override {
        (uint256 amount, uint256 tokenId) = abi.decode(moreInfo, (uint256, uint256));
        // Withdraw all wnativeToken to nativeToken
        IWETH(WNATIVETOKEN).withdraw(IWETH(WNATIVETOKEN).balanceOf(address(this)));
        // buyAndCreateLpIfPossible will mint the MemeToken to msg.sender and send the surplus nativeToken back to msg.sender(adapter)
        IArenaTokenManager(pool).buyAndCreateLpIfPossible{value: address(this).balance}(amount, tokenId);
        // Get the token info by tokenId and transfer the token to the to address
        IArenaTokenManager.TokenParameters memory tokenParams = IArenaTokenManager(pool).tokenParams(tokenId);
        uint256 toTokenBalance = IERC20(tokenParams.tokenContractAddress).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(tokenParams.tokenContractAddress), to, toTokenBalance);
        // refund the surplus nativeToken
        uint256 nativeTokenBalance = address(this).balance;
        if (nativeTokenBalance > 0) {
            IWETH(WNATIVETOKEN).deposit{value: nativeTokenBalance}();
            uint256 payerOrigin;
            assembly {
                let size := calldatasize()
                payerOrigin := calldataload(sub(size, 32))
            }
            address payerOriginAddress;
            if ((payerOrigin & ORIGIN_PAYER) == ORIGIN_PAYER) {
                payerOriginAddress = address(uint160(uint256(payerOrigin)));
            }
            if (payerOriginAddress != address(0)) {
                IWETH(WNATIVETOKEN).transfer(payerOriginAddress, nativeTokenBalance);
            }
        }
    }

    // fromToken == MemeToken, toToken == WNativeToken
    function sellQuote(
        address to,
        address pool, // BondingCurve contract, TokenManager
        bytes memory moreInfo
    ) external override {
        (uint256 amount, uint256 tokenId) = abi.decode(moreInfo, (uint256, uint256));
        // sell will burn the MemeToken from msg.sender and send the nativeToken to msg.sender(adapter)
        IArenaTokenManager(pool).sell(amount, tokenId);
        // Withdraw all wnativeToken to nativeToken
        IWETH(WNATIVETOKEN).deposit{value: address(this).balance}();
        IWETH(WNATIVETOKEN).transfer(to, IWETH(WNATIVETOKEN).balanceOf(address(this)));
    }

    receive() external payable {
       emit Received(msg.sender, msg.value);
   }
}
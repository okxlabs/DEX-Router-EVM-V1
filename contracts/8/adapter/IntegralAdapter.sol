// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/IIntegral.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
contract IntegralAdapter is IAdapter {

    address immutable TWAPRELAY_ADDRESS;
    
    constructor(address _twaprelay){
        TWAPRELAY_ADDRESS = _twaprelay;
    }

    function _integralSwap(
        address _to,
        address ,
        bytes memory moreInfo
    ) internal{
        (address _tokenIn, address _tokenOut, uint256 _amountOutMin, uint32 _submitDeadline) = abi.decode(
            moreInfo, (address, address, uint256, uint32));
        uint256 _amountIn = IERC20(_tokenIn).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(_tokenIn),
            TWAPRELAY_ADDRESS,
            _amountIn
        );
        ITwapRelay(TWAPRELAY_ADDRESS).sell(SellParams(
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            false,
            _to,
            //_gasLimit,
            _submitDeadline
        ));
    }


    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _integralSwap(to, pool, moreInfo);
    }

    function sellQuote(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override {
        _integralSwap(to, pool, moreInfo);
    }

}
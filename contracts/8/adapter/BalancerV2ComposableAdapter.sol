// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBalancerV2Composable.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";


// for two tokens
contract BalancerV2ComposableAdapter is IAdapter {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable VAULT_ADDRESS;
    address public immutable WETH_ADDRESS;

    constructor (
        address _balancerVault, 
        address _weth
    ) {
        VAULT_ADDRESS = _balancerVault;
        WETH_ADDRESS = _weth;
    }

    function _swap(
        bytes32 poolId, 
        address sourceToken, 
        address targetToken
    ) internal {
        // get sell Amount
        uint256 sellAmount =  IERC20(sourceToken).balanceOf(address(this));

        // get singleSwap
        IBalancerV2Vault.SingleSwap memory singleSwap;
        singleSwap.poolId = poolId;
        singleSwap.kind = IBalancerV2Vault.SwapKind.GIVEN_IN;
        singleSwap.assetIn = sourceToken == ETH_ADDRESS
            ? WETH_ADDRESS
            : sourceToken;
        singleSwap.assetOut = targetToken == ETH_ADDRESS
            ? WETH_ADDRESS
            : targetToken;
        singleSwap.amount = sellAmount;

        // get fund
        IBalancerV2Vault.FundManagement memory fund;
        fund.sender = address(this);
        fund.recipient = address(this);

        // approve sell amount
        // bb-a-token will be auto approved to a very large sellamount: 
        // for example: bb-a-usdt 115792089237316195423570985008687907853269984665640564039457584007913129639935

        uint256 _allowance = IERC20(sourceToken).allowance( address(this), VAULT_ADDRESS);
        if ( _allowance == 0) {
            SafeERC20.safeApprove(
                IERC20(sourceToken == ETH_ADDRESS ? WETH_ADDRESS : sourceToken),
                VAULT_ADDRESS,
                sellAmount
            );
        } else {
            require(_allowance > sellAmount, "invalid allowance");
        }

        // swap, the limit parameter is 0 for the time being, 
        // and the slippage point is not considered for the time being
        IBalancerV2Vault(VAULT_ADDRESS).swap(
            singleSwap,
            fund,
            0,
            block.timestamp
        );
    }

 
    function _balanverV2ComposableSwapTripleHop(
        address to,
        address, /*vault*/
        bytes memory moreInfo
    ) internal {
        (Hop memory firstHop, Hop memory secondHop, Hop memory thirdHop) = abi.decode(moreInfo, (Hop,Hop,Hop) );

        // first Hop
        _swap(firstHop.poolId, firstHop.sourceToken, firstHop.targetToken);

        // second Hop
        _swap(secondHop.poolId, secondHop.sourceToken, secondHop.targetToken);

        //third Hop
        _swap(thirdHop.poolId, thirdHop.sourceToken, thirdHop.targetToken);

        if (to != address(this)) {
            if (thirdHop.targetToken == ETH_ADDRESS) thirdHop.targetToken = WETH_ADDRESS;
            SafeERC20.safeTransfer(
                IERC20(thirdHop.targetToken),
                to,
                IERC20(thirdHop.targetToken).balanceOf(address(this))
            );
        }
    }

    function _balanverV2ComposableSwapDoubleHop(
        address to,
        address, /*vault*/
        bytes memory moreInfo
    ) internal {
        (Hop memory firstHop, Hop memory secondHop) = abi.decode(moreInfo, (Hop,Hop) );

        // first Hop
        _swap(firstHop.poolId, firstHop.sourceToken, firstHop.targetToken);

        // second Hop
        _swap(secondHop.poolId, secondHop.sourceToken, secondHop.targetToken);
       
        if (to != address(this)) {
            if (secondHop.targetToken == ETH_ADDRESS) secondHop.targetToken = WETH_ADDRESS;
            SafeERC20.safeTransfer(
                IERC20(secondHop.targetToken),
                to,
                IERC20(secondHop.targetToken).balanceOf(address(this))
            );
        }
    }

    function sellBase(
        address to,
        address vault,
        bytes memory moreInfo
    ) external override {
        (uint8 Hops, bytes memory data) = abi.decode( moreInfo, (uint8, bytes) );
        if (Hops == 2) {
            _balanverV2ComposableSwapDoubleHop(to, vault, data);
        } else if (Hops == 3) {
            _balanverV2ComposableSwapTripleHop(to, vault, data);
        } else {
            revert("Hops only can be 2 or 3.");
        }
    }

    function sellQuote(
        address to,
        address vault,
        bytes memory moreInfo
    ) external override {
        (uint8 Hops, bytes memory data) = abi.decode( moreInfo, (uint8, bytes) );
        if (Hops == 2) {
            _balanverV2ComposableSwapDoubleHop(to, vault, data);
        } else if (Hops == 3) {
            _balanverV2ComposableSwapTripleHop(to, vault, data);
        }  else {
            revert("Hops only can be 2 or 3.");
        }
    }

    event Received(address, uint256);

    receive() external payable {
        require(msg.value > 0, "receive error");
        emit Received(msg.sender, msg.value);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/IAdapter.sol";
import "../interfaces/IAspectaKeyPool.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title AspectaAdapter
/// @notice AspectaAdapter is a contract that allows to swap between NativeToken and Key
/// @dev For sellQuote, the fromToken is the key, the key is always keep under the control
/// of the seller address and not transferable, so refund logic is not needed.
contract AspectaAdapter is IAdapter, Ownable {
    uint256 constant ORIGIN_PAYER = 0x3ca20afc2ccc0000000000000000000000000000000000000000000000000000; // 0x3ca20afc
    uint256 constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    address constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable WNATIVETOKEN;

    mapping(address => bool) public dexRouter;

    event Received(address sender, uint256 amount);
    // To record swap info for cases that the OrderRecord event is invalid.
    // direction: true for sellBase(buy key), false for sellQuote(sell key)
    event OrderRecord(bool direction, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);
    event DexRouterSet(address dexRouter, bool isDexRouter);

    constructor(address payable wNativeToken) {
        WNATIVETOKEN = wNativeToken;
    }

    modifier onlyDexRouter() {
        require(dexRouter[msg.sender], "AspectaAdapter: only DexRouter can call this adapter");
        _;
    }

    // fromToken == WNativeToken, toToken == Key
    function sellBase(
        address to,
        address pool,
        bytes memory moreInfo
    ) external override onlyDexRouter {
        (uint256 amount) = abi.decode(moreInfo, (uint256));
        // Withdraw all wnativeToken to nativeToken
        IWETH(WNATIVETOKEN).withdraw(IWETH(WNATIVETOKEN).balanceOf(address(this)));
        uint256 fromAmount = address(this).balance;
        // buyByRouter will increase the key balance of `to` address and send the surplus nativeToken to `to` address,
        // and will revert if the nativeToken is insufficient
        // IAspectaKeyPool(pool).buyByRouter{value: address(this).balance}(amount, to);
        _call(pool, abi.encodeWithSelector(IAspectaKeyPool.buyByRouter.selector, amount, to), address(this).balance);
        // refund the surplus nativeToken to payerOrigin
        address payerOrigin = _getPayerOrigin();
        uint256 refundAmount = address(this).balance;
        if (refundAmount > 0 && payerOrigin != address(0)) {
            IWETH(WNATIVETOKEN).deposit{value: refundAmount}();
            SafeERC20.safeTransfer(IERC20(WNATIVETOKEN), payerOrigin, refundAmount);
        }
        emit OrderRecord(true, NATIVE_ADDRESS, pool, fromAmount, amount);
    }

    // fromToken == Key, toToken == NativeToken and the nativeToken is send to recepient address
    // So actually the aspecta adapter supports the sellQuote toToken commission in DexRouter, but here we keep the same usage as before.
    function sellQuote(
        address, // to
        address pool,
        bytes memory moreInfo
    ) external override onlyDexRouter {
        (uint256 amount, uint256 minPrice, uint256 fee, address feeRecipient) = abi.decode(moreInfo, (uint256, uint256, uint256, address));
        address payerOrigin = _getPayerOrigin();
        require(payerOrigin != address(0), "AspectaAdapter: payerOrigin is zero");
        uint256 toAmountBefore = payerOrigin.balance;
        // sellByRouter will decrease the key balance of tx.origin and send the nativeToken to recipient
        // IAspectaKeyPool(pool).sellByRouter(receiver, amount, minPrice, fee, feeRecipient);
        _call(pool, abi.encodeWithSelector(IAspectaKeyPool.sellByRouter.selector, payerOrigin, amount, minPrice, fee, feeRecipient), 0);
        emit OrderRecord(false, pool, NATIVE_ADDRESS, amount, payerOrigin.balance - toAmountBefore);
    }
    
    // call the target contract with value and revert with related string error.
    function _call(address target, bytes memory data, uint256 value) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (success) {
            return;
        }
        if (result.length < 4) {
            revert("Aspecta: Unknown error");
        }
        bytes4 selector;
        assembly {
            selector := mload(add(result, 32))
        }
        if (selector == 0x6ea6aa1e) {         // TradeNotStarted()
            revert("Aspecta: TradeNotStarted");
        } else if (selector == 0x97d7aeca) {  // MaxKeyHoldExceeded()
            revert("Aspecta: MaxKeyHoldExceeded");
        } else if (selector == 0xd131c780) {  // OpeningPeriodBuyLimitExceeded()
            revert("Aspecta: OpeningPeriodBuyLimitExceeded");
        } else if (selector == 0x03eb8b54) {  // InsufficientFunds(uint256 expected, uint256 received)
            revert("Aspecta: InsufficientFunds");
        } else if (selector == 0xd7d43683) {  // InvalidKeys()
            revert("Aspecta: InvalidKeys");
        } else if (selector == 0x0b310b86) {  // InsufficientKeys()
            revert("Aspecta: InsufficientKeys");
        } else if (selector == 0xc3ac4d7d) {  // MinPriceNotMet(uint256 minPrice, uint256 received)
            revert("Aspecta: MinPriceNotMet");
        } else {
            revert(string(result));
        }
    }

    receive() external payable {
       emit Received(msg.sender, msg.value);
   }

    function setDexRouter(address _dexRouter, bool _isDexRouter) external onlyOwner {
        dexRouter[_dexRouter] = _isDexRouter;
        emit DexRouterSet(_dexRouter, _isDexRouter);
    }

    function _getPayerOrigin() internal pure returns (address payerOriginAddr) {
        uint256 _payerOrigin;
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
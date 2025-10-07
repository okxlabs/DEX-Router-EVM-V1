// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

// contracts/8/libraries/Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return payable(account);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// contracts/8/interfaces/IAdapter.sol

interface IAdapter {
    function sellBase(
        address to,
        address pool,
        bytes memory data
    ) external;

    function sellQuote(
        address to,
        address pool,
        bytes memory data
    ) external;
}

// contracts/8/interfaces/IDaiLikePermit.sol

/// @title Interface for DAI-style permits
interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// contracts/8/interfaces/IERC20.sol

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// contracts/8/interfaces/IERC20Permit.sol

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// contracts/8/interfaces/IFourMeme.sol

interface ITokenManager2 {

    function buyTokenAMAP(
        address token,
        address to, 
        uint256 funds, 
        uint256 minAmount
    ) external payable;

    function sellToken(
        address token, 
        uint256 amount
    ) external;

    function sellToken(
        uint256 origin, //The platform from which the request is sent. Pass 0 if not applicable.
        address token, //The address of the token to be sold.
        address from, //The address of the token owner(tx.orgin == from).
        uint256 amount, //The amount of tokens to be sold.
        uint256 minFunds, //The minimum amount of funds to be received after the sale.
        uint256 feeRate, //The router’s fee rate. 100 means 1%, and 10 means 0.1%. (MAX 5%)
        address feeRecipient//The address that will receive the fee.
    ) external;
}

interface ITokenManagerHelper3 {
    /// @notice Sell tokens for ETH
    /// @dev If the user wants to sell tokens for BNB through a third-party router, the original sender of the transaction must be the token owner.
    /// This method is only applicable for ERC20/ERC20 trading pairs (quote token is not address(0)). It is not supported for BNB trading pairs.
    /// The trading fee will be collected in the quote token (ERC20) instead of BNB.
    function sellForEth(
        uint256 origin, // The platform from which the request is sent. Pass 0 if not applicable.
        address token, // The address of the token to sell
        address from, // The address of the token owner (tx.origin must equal from)
        uint256 amount, // The amount of tokens to sell
        uint256 minFunds, // The minimum amount of BNB to receive
        uint256 feeRate, // The fee rate for the transaction. 100 means 1%, 10 means 0.1%. (MAX 5%)
        address feeRecipient // The address that will receive the fee (in quote token)
    ) external;
}

// contracts/8/interfaces/IWETH.sol

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// contracts/8/libraries/RevertReasonForwarder.sol

library RevertReasonForwarder {
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// contracts/8/libraries/SafeMath.sol

library SafeMath {
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wad() public pure returns (uint256) {
        return WAD;
    }

    function ray() public pure returns (uint256) {
        return RAY;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function sqrt(uint256 a) internal pure returns (uint256 b) {
        if (a > 3) {
            b = a;
            uint256 x = a / 2 + 1;
            while (x < b) {
                b = x;
                x = (a / x + x) / 2;
            }
        } else if (a != 0) {
            b = 1;
        }
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b) / WAD;
    }

    function wmulRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, b), WAD / 2) / WAD;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b) / RAY;
    }

    function rmulRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, b), RAY / 2) / RAY;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, WAD), b);
    }

    function wdivRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, WAD), b / 2) / b;
    }

    function rdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, RAY), b);
    }

    function rdivRound(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(mul(a, RAY), b / 2) / b;
    }

    function wpow(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = WAD;
        while (n > 0) {
            if (n % 2 != 0) {
                result = wmul(result, x);
            }
            x = wmul(x, x);
            n /= 2;
        }
        return result;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256) {
        uint256 result = RAY;
        while (n > 0) {
            if (n % 2 != 0) {
                result = rmul(result, x);
            }
            x = rmul(x, x);
            n /= 2;
        }
        return result;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}

// contracts/8/libraries/SafeERC20.sol

// File @1inch/solidity-utils/contracts/libraries/SafeERC20.sol@v2.1.1

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        forceApprove(token, spender, value);
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (!_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value))
            {
                revert ForceApproveFailed();
            }
        }
    }

    

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        bool success;
        if (permit.length == 32 * 7) {
            success = _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        } else if (permit.length == 32 * 8) {
            success = _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        } else {
            revert SafePermitBadLength();
        }
        if (!success) RevertReasonForwarder.reRevert();
    }

    function _makeCall(IERC20 token, bytes4 selector, address to, uint256 amount) private returns(bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
    }

    function _makeCalldataCall(IERC20 token, bytes4 selector, bytes calldata args) private returns(bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 { success := gt(extcodesize(token), 0) }
                default { success := and(gt(returndatasize(), 31), eq(mload(0), 1)) }
            }
        }
    }
}

// contracts/8/adapter/FourMemeAdapter2.sol

contract FourMemeAdapter2 is IAdapter {

    uint256 constant MINAMOUNT = 0;
    uint256 constant PLATFORM = 0;
    uint256 constant GWEI = 10 ** 9;
    address public immutable WNATIVE;
    address public immutable TOKENMANAGER2;//0x5c952063c7fc8610FFDB798152D69F0B9550762b bsc

    struct TradeInfo {
        address fundAddress;
        address tokenAddress;
        bool buyMeme;
        uint256 sellMemeAmount;
        uint256 sellCommissionRate1;
        address sellCommissionReceiver1;
        uint256 sellCommissionRate2;
        address sellCommissionReceiver2;
        uint256 minReturnAmount;
    }

    event Received(address sender, uint256 amount);
    // To record swap info for cases that the OrderRecord event is invalid.
    // direction: true for buy meme, false for sell meme
    event OrderRecord(bool direction, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);

    constructor (
        address Wnative,
        address TokenManager2
    ) {
        WNATIVE = Wnative;
        TOKENMANAGER2 = TokenManager2;
    }

    function _fourMemeTrading(
        address to,
        bytes memory moreInfo
    ) private {
        uint256 amountIn;
        uint256 amountOut;
        TradeInfo memory tradeInfo = abi.decode(moreInfo, (TradeInfo));

        if (tradeInfo.buyMeme) {
            uint256 dust;
            amountOut = IERC20(tradeInfo.tokenAddress).balanceOf(to);
            if (tradeInfo.fundAddress == WNATIVE){
                amountIn = IERC20(WNATIVE).balanceOf(address(this));
                IWETH(WNATIVE).withdraw(amountIn);
                ITokenManager2(TOKENMANAGER2).buyTokenAMAP{value: amountIn}(tradeInfo.tokenAddress, to, amountIn, MINAMOUNT);
                dust = address(this).balance;
                if (dust > 0) {
                    (bool success, ) = to.call{value: dust}("");
                    require(success, "Transfer failed");
                }
            }else{
                amountIn = IERC20(tradeInfo.fundAddress).balanceOf(address(this));
                IERC20(tradeInfo.fundAddress).approve(TOKENMANAGER2, amountIn);
                ITokenManager2(TOKENMANAGER2).buyTokenAMAP(tradeInfo.tokenAddress, to, amountIn, MINAMOUNT);
                dust = IERC20(tradeInfo.fundAddress).balanceOf(address(this));
                if (dust > 0) {
                    IERC20(tradeInfo.fundAddress).transfer(to, dust);
                }
            }
            amountOut = IERC20(tradeInfo.tokenAddress).balanceOf(to) - amountOut;
            emit OrderRecord(true, tradeInfo.fundAddress, tradeInfo.tokenAddress, amountIn - dust, amountOut);
        } else {
            amountIn = tradeInfo.sellMemeAmount;
            if (amountIn % GWEI != 0) {
                amountIn = (amountIn / GWEI) * GWEI;
                require(amountIn > 0, "processed amountIn is 0");
            }
            address fundToken = tradeInfo.fundAddress == WNATIVE ? address(0) : tradeInfo.fundAddress;
            (bool success, ) = TOKENMANAGER2.call(abi.encodeWithSelector(0x930cc050, PLATFORM, tradeInfo.tokenAddress, tx.origin, address(this), amountIn, 1));
            require(success, "sellToken in fourmeme failed");
            amountOut = _getBalance(fundToken, address(this));
            _safeTransfer(fundToken, to, amountOut);
            
            emit OrderRecord(false, tradeInfo.tokenAddress, tradeInfo.fundAddress, amountIn, amountOut);
        }
    }

    function _getBalance(address token, address user) internal view returns (uint256) {
        if (token == address(0)) {
            return address(user).balance;
        } else {
            return IERC20(token).balanceOf(user);
        }
    }

    function _safeTransfer(address token, address receiver, uint256 amount) internal {
        if (token == address(0)) {
            IWETH(WNATIVE).deposit{value: address(this).balance}();
            SafeERC20.safeTransfer(IERC20(WNATIVE), receiver, amount);
        } else {
            SafeERC20.safeTransfer(IERC20(token), receiver, amount);
        }
    }

    function sellBase(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _fourMemeTrading(to,moreInfo);
    }

    function sellQuote(
        address to,
        address ,
        bytes memory moreInfo
    ) external override {
        _fourMemeTrading(to, moreInfo);
    }

    receive() external payable {
       emit Received(msg.sender, msg.value);
   }
}


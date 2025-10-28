pragma solidity ^0.8.10;

interface IMooniswap {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposited(address indexed account, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Swapped(
        address indexed account,
        address indexed src,
        address indexed dst,
        uint256 amount,
        uint256 result,
        uint256 srcBalance,
        uint256 dstBalance,
        uint256 totalSupply,
        address referral
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawn(address indexed account, uint256 amount);

    function BASE_SUPPLY() external view returns (uint256);
    function FEE_DENOMINATOR() external view returns (uint256);
    function REFERRAL_SHARE() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decayPeriod() external pure returns (uint256);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function deposit(uint256[] memory amounts, uint256[] memory minAmounts)
        external
        payable
        returns (uint256 fairSupply);
    function factory() external view returns (address);
    function fee() external view returns (uint256);
    function getBalanceForAddition(address token) external view returns (uint256);
    function getBalanceForRemoval(address token) external view returns (uint256);
    function getReturn(address src, address dst, uint256 amount) external view returns (uint256);
    function getTokens() external view returns (address[] memory);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function isToken(address) external view returns (bool);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function rescueFunds(address token, uint256 amount) external;
    function swap(address src, address dst, uint256 amount, uint256 minReturn, address referral)
        external
        payable
        returns (uint256 result);
    function symbol() external view returns (string memory);
    function tokens(uint256) external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external;
    function virtualBalancesForAddition(address) external view returns (uint216 balance, uint40 time);
    function virtualBalancesForRemoval(address) external view returns (uint216 balance, uint40 time);
    function volumes(address) external view returns (uint128 confirmed, uint128 result);
    function withdraw(uint256 amount, uint256[] memory minReturns) external;
}

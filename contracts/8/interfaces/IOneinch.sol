pragma solidity ^0.8.10;

interface IOneinch {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event DecayPeriodVoteUpdate(
        address indexed user, uint256 decayPeriod, bool isDefault, uint256 amount
    );
    event Deposited(
        address indexed sender,
        address indexed receiver,
        uint256 share,
        uint256 token0Amount,
        uint256 token1Amount
    );
    event Error(string reason);
    event FeeVoteUpdate(
        address indexed user, uint256 fee, bool isDefault, uint256 amount
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SlippageFeeVoteUpdate(
        address indexed user, uint256 slippageFee, bool isDefault, uint256 amount
    );
    event Swapped(
        address indexed sender,
        address indexed receiver,
        address indexed srcToken,
        address dstToken,
        uint256 amount,
        uint256 result,
        uint256 srcAdditionBalance,
        uint256 dstRemovalBalance,
        address referral
    );
    event Sync(
        uint256 srcBalance,
        uint256 dstBalance,
        uint256 fee,
        uint256 slippageFee,
        uint256 referralShare,
        uint256 governanceShare
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawn(
        address indexed sender,
        address indexed receiver,
        uint256 share,
        uint256 token0Amount,
        uint256 token1Amount
    );

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decayPeriod() external view returns (uint256);
    function decayPeriodVote(uint256 vote) external;
    function decayPeriodVotes(address user) external view returns (uint256);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
    function deposit(uint256[2] memory maxAmounts, uint256[2] memory minAmounts)
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);
    function depositFor(
        uint256[2] memory maxAmounts,
        uint256[2] memory minAmounts,
        address target
    ) external payable returns (uint256 fairSupply, uint256[2] memory receivedAmounts);
    function discardDecayPeriodVote() external;
    function discardFeeVote() external;
    function discardSlippageFeeVote() external;
    function fee() external view returns (uint256);
    function feeVote(uint256 vote) external;
    function feeVotes(address user) external view returns (uint256);
    function getBalanceForAddition(address token) external view returns (uint256);
    function getBalanceForRemoval(address token) external view returns (uint256);
    function getReturn(address src, address dst, uint256 amount)
        external
        view
        returns (uint256);
    function getTokens() external view returns (address[] memory tokens);
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);
    function mooniswapFactoryGovernance() external view returns (address);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function rescueFunds(address token, uint256 amount) external;
    function setMooniswapFactoryGovernance(address newMooniswapFactoryGovernance)
        external;
    function slippageFee() external view returns (uint256);
    function slippageFeeVote(uint256 vote) external;
    function slippageFeeVotes(address user) external view returns (uint256);
    function swap(
        address src,
        address dst,
        uint256 amount,
        uint256 minReturn,
        address referral
    ) external payable returns (uint256 result);
    function swapFor(
        address src,
        address dst,
        uint256 amount,
        uint256 minReturn,
        address referral,
        address receiver
    ) external payable returns (uint256 result);
    function symbol() external view returns (string memory);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function tokens(uint256 i) external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
    function transferOwnership(address newOwner) external;
    function virtualBalancesForAddition(address)
        external
        view
        returns (uint216 balance, uint40 time);
    function virtualBalancesForRemoval(address)
        external
        view
        returns (uint216 balance, uint40 time);
    function virtualDecayPeriod() external view returns (uint104, uint104, uint48);
    function virtualFee() external view returns (uint104, uint104, uint48);
    function virtualSlippageFee() external view returns (uint104, uint104, uint48);
    function volumes(address) external view returns (uint128 confirmed, uint128 result);
    function withdraw(uint256 amount, uint256[] memory minReturns)
        external
        returns (uint256[2] memory withdrawnAmounts);
    function withdrawFor(uint256 amount, uint256[] memory minReturns, address target)
        external
        returns (uint256[2] memory withdrawnAmounts);
}

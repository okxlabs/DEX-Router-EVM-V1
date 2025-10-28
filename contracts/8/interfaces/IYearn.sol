// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
interface yVault {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function available() external view returns (uint256);
    function balance() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function controller() external view returns (address);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function deposit(uint256 _amount) external;
    function depositAll() external;
    function earn() external;
    function getPricePerFullShare() external view returns (uint256);
    function governance() external view returns (address);
    function harvest(address reserve, uint256 amount) external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function max() external view returns (uint256);
    function min() external view returns (uint256);
    function name() external view returns (string memory);
    function setController(address _controller) external;
    function setGovernance(address _governance) external;
    function setMin(uint256 _min) external;
    function symbol() external view returns (string memory);
    function token() external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;
    function pricePerShare() external view returns (uint256);
}

interface yvVault {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event StrategyAdded(address indexed strategy, uint256 debtLimit, uint256 rateLimit, uint256 performanceFee);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtLimit
    );
    event Transfer(address indexed sender, address indexed receiver, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function acceptGovernance() external;
    function activation() external view returns (uint256);
    function addStrategy(address _strategy, uint256 _debtLimit, uint256 _rateLimit, uint256 _performanceFee) external;
    function addStrategyToQueue(address _strategy) external;
    function allowance(address arg0, address arg1) external view returns (uint256);
    function apiVersion() external pure returns (string memory);
    function approve(address _spender, uint256 _value) external returns (bool);
    function availableDepositLimit() external view returns (uint256);
    function balanceOf(address arg0) external view returns (uint256);
    function balanceSheetOfStrategy(address _strategy) external view returns (uint256);
    function creditAvailable() external view returns (uint256);
    function creditAvailable(address _strategy) external view returns (uint256);
    function debtLimit() external view returns (uint256);
    function debtOutstanding() external view returns (uint256);
    function debtOutstanding(address _strategy) external view returns (uint256);
    function decimals() external view returns (uint256);
    function decreaseAllowance(address _spender, uint256 _value) external returns (bool);
    function deposit() external returns (uint256);
    function deposit(uint256 _amount) external returns (uint256);
    function deposit(uint256 _amount, address _recipient) external returns (uint256);
    function depositLimit() external view returns (uint256);
    function emergencyShutdown() external view returns (bool);
    function expectedReturn() external view returns (uint256);
    function expectedReturn(address _strategy) external view returns (uint256);
    function governance() external view returns (address);
    function guardian() external view returns (address);
    function guestList() external view returns (address);
    function increaseAllowance(address _spender, uint256 _value) external returns (bool);
    function lastReport() external view returns (uint256);
    function managementFee() external view returns (uint256);
    function maxAvailableShares() external view returns (uint256);
    function migrateStrategy(address _oldVersion, address _newVersion) external;
    function name() external view returns (string memory);
    function nonces(address arg0) external view returns (uint256);
    function performanceFee() external view returns (uint256);
    function permit(address owner, address spender, uint256 amount, uint256 expiry, bytes memory signature)
        external
        returns (bool);
    function pricePerShare() external view returns (uint256);
    function removeStrategyFromQueue(address _strategy) external;
    function report(uint256 _gain, uint256 _loss, uint256 _debtPayment) external returns (uint256);
    function revokeStrategy() external;
    function revokeStrategy(address _strategy) external;
    function rewards() external view returns (address);
    function setDepositLimit(uint256 _limit) external;
    function setEmergencyShutdown(bool _active) external;
    function setGovernance(address _governance) external;
    function setGuardian(address _guardian) external;
    function setGuestList(address _guestList) external;
    function setManagementFee(uint256 _fee) external;
    function setName(string memory _name) external;
    function setPerformanceFee(uint256 _fee) external;
    function setRewards(address _rewards) external;
    function setSymbol(string memory _symbol) external;
    function setWithdrawalQueue(address[20] memory _queue) external;
    function strategies(address arg0)
        external
        view
        returns (
            uint256 performanceFee,
            uint256 activation,
            uint256 debtLimit,
            uint256 rateLimit,
            uint256 lastReport,
            uint256 totalDebt,
            uint256 totalGain,
            uint256 totalLoss
        );
    function sweep(address _token) external;
    function sweep(address _token, uint256 _value) external;
    function symbol() external view returns (string memory);
    function token() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalBalanceSheet(address[40] memory _strategies) external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function updateStrategyDebtLimit(address _strategy, uint256 _debtLimit) external;
    function updateStrategyPerformanceFee(address _strategy, uint256 _performanceFee) external;
    function updateStrategyRateLimit(address _strategy, uint256 _rateLimit) external;
    function withdraw() external returns (uint256);
    function withdraw(uint256 _shares) external returns (uint256);
    function withdraw(uint256 _shares, address _recipient) external returns (uint256);
    function withdrawalQueue(uint256 arg0) external view returns (address);
}

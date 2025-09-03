pragma solidity ^0.8.0;
pragma abicoder v2;

interface IRocketDepositPool {

    function deposit() external payable;
}
interface IRETH {
    function burn(uint256 _rethAmount) external;
}

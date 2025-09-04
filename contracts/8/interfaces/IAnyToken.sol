pragma solidity 0.8.17;
pragma abicoder v2;
interface IAnyToken {
    function withdraw() external returns (uint);
    function underlying() external returns (address);
}

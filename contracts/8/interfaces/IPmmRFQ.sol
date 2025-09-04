pragma solidity 0.8.17;
pragma abicoder v2;

struct OrderRFQ {
    uint256 info;
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
    address settler;
}

interface IPmmRFQ {
    function fillOrderRFQTo(
        OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target
    )
        external
        payable
        returns (
            uint256 filledMakingAmount,
            uint256 filledTakingAmount,
            bytes32 orderHash
        );
}

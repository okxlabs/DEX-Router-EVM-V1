/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;


struct IOrder {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender;  // equals to Zero address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 offsets;
    // bytes makerAssetData;
    // bytes takerAssetData;
    // bytes getMakingAmount; // this.staticcall(abi.encodePacked(bytes, swapTakerAmount)) => (swapMakerAmount)
    // bytes getTakingAmount; // this.staticcall(abi.encodePacked(bytes, swapMakerAmount)) => (swapTakerAmount)
    // bytes predicate;       // this.staticcall(bytes) => (bool)
    // bytes permit;          // On first fill: permit.1.call(abi.encodePacked(permit.selector, permit.2))
    // bytes preInteraction;
    // bytes postInteraction;
    bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
}

interface ILimitOrder {
    function fillOrderTo(
        IOrder calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target
    ) external payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);
}
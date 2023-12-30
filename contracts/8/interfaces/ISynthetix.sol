/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ISNXPROXY {

  function exchangeAtomically(
      bytes32 sourceCurrencyKey,
      uint sourceAmount,
      bytes32 destinationCurrencyKey,
      bytes32 trackingCode,
      uint minAmount
  ) external returns (uint amountReceived);

  function exchangeWithTracking(
      bytes32 sourceCurrencyKey,
      uint sourceAmount,
      bytes32 destinationCurrencyKey,
      address rewardAddress,
      bytes32 trackingCode
  ) external returns (uint amountReceived);

}


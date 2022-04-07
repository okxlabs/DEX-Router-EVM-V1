// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder  v2;

contract MockRecover{

    bytes32 public constant DOMAIN_SEPARATOR = 0xb62baa298dba2097375700cb4111f22d2780f2b74a67bd22ae424889eea981f3;


    function hashToSign(string memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashOrder(order))
        );
    }

    function hashOrder(string memory order) public pure returns (bytes32){
        return keccak256(abi.encode(order));
    }

    function recover(bytes32 mshash, uint8 v, bytes32 r, bytes32 s) public pure returns (address){
      address signatureAddress = ecrecover(mshash, v, r, s);
      return signatureAddress;
    }
}
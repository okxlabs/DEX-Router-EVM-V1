// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// Handle authorizations in dex platform
contract PmmConstantsTool {

    function calPMMConstants(string memory name, string memory version, uint256 chainid, address dexRouterAddress) 
      public pure
      returns (bytes32 _CACHED_DOMAIN_SEPARATOR, bytes32 _HASHED_NAME, bytes32 _HASHED_VERSION, bytes32 _TYPE_HASH) 
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion,
            chainid,
            dexRouterAddress
        );
        _TYPE_HASH = typeHash;
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash,
        uint256 chainid,
        address dexRouterAddress
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    chainid,
                    dexRouterAddress
                )
            );
    }
}

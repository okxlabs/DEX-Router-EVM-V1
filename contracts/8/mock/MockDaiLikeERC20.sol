// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IDaiLikePermit.sol";

contract MockDaiLikeERC20 is ERC20, IDaiLikePermit {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    // For testing purpose only
    function mint(address guy, uint256 wad) public {
        _mint(guy, wad);
    }

    function permit(
        address holder,
        address /*spender*/,
        uint256 /*nonce*/,
        uint256 /*expiry*/,
        bool /*allowed*/,
        uint8 /*v*/,
        bytes32 /*r*/,
        bytes32 /*s*/
    ) external pure override{
        holder;
    }

    function nonces(address holder) external pure returns(uint nonce){
        holder;
        return nonce;
    }
}

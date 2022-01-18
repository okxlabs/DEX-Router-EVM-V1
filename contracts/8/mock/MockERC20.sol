// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockERC20 is ERC20Upgradeable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) {
        __ERC20_init(name, symbol);
        _mint(msg.sender, supply);
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20, ERC20Permit} from "./ERC20Permit.sol";

contract ERC20PermitMock is ERC20Permit {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

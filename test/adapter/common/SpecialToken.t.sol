// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@okxlabs/interfaces/IERC20.sol";

/**
 * @title SpecialToken
 * @dev Helper contract for dealing tokens via on-chain transfers instead of stdStorage
 * @dev Maintains a mapping of token addresses to known wealthy holders
 */
contract SpecialToken is Test {
    
    // 1 to 1 mapping of token address to wealthy holder address
    mapping(address => address) public wealthyHolders;
    
    constructor() {
        _setupWealthyHolders();
    }
    
    /**
     * @dev Setup known wealthy holders for common tokens
     */
    function _setupWealthyHolders() internal {
        // Aave aUSDT
        address AETH_USDT = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;
        wealthyHolders[AETH_USDT] = 0x18709E89BD403F470088aBDAcEbE86CC60dda12e; // Aave Collector
    }
    
    /**
     * @dev Add wealthy holder for a token
     * @param token The token address
     * @param holder The wealthy holder address
     */
    function addWealthyHolder(address token, address holder) external {
        wealthyHolders[token] = holder;
    }
    
    /**
     * @dev Check if a token has a wealthy holder configured
     * @param token The token address
     * @return true if the token has a wealthy holder
     */
    function hasWealthyHolders(address token) external view returns (bool) {
        return wealthyHolders[token] != address(0);
    }
    
    /**
     * @dev Deal tokens to a recipient via on-chain transfer
     * @param token The token address
     * @param to The recipient address  
     * @param amount The amount to transfer
     */
    function specialDeal(address token, address to, uint256 amount) external {
        
        address holder = wealthyHolders[token];
        uint256 balance = IERC20(token).balanceOf(holder);
            
        if (balance >= amount) {
            vm.prank(holder);
            try IERC20(token).transfer(to, amount) returns (bool success) {
                if (success) {
                    return; // Successfully transferred
                }
            } catch {
                revert("SpecialToken: Unable to transfer tokens - insufficient balance or transfer failed");
            }
        }
    }
} 
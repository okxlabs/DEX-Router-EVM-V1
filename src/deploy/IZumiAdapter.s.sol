// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/IzumiAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    address factory = 0x8c7d3063579BdB0b90997e18A770eaE32E1eBb08;
    address WETH = 0x5300000000000000000000000000000000000004;

    function run() public {
        require(deployer == 0x358506b4C5c441873AdE429c5A2BE777578E2C6f, "wrong deployer! change the private key");

        // deploy on scroll
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 534352 , "must be scrollchain");
      
        address adapter = address(new IZumiAdapter(payable(WETH), factory));
        console2.log("IZumiAdapter deployed on scroll: %s", adapter);

        vm.stopBroadcast();
    }
}

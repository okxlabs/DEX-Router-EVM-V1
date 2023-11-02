// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/DnyFeeAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x358506b4C5c441873AdE429c5A2BE777578E2C6f, "wrong deployer! change the private key");
        // deploy on scroll
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 534352, "must be scroll");

        address adapter = address(new DnyFeeAdapter());
        console2.log("DnyFeeAdapter deployed scroll: %s", adapter);

        vm.stopBroadcast();
    }
}


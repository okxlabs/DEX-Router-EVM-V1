// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/ThenaAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56, "must be bsc");

        address adapter = address(new ThenaAdapter());
        console2.log("SolidlyseriesAdapter deployed on bsc: %s", adapter);

        vm.stopBroadcast();
    }
}

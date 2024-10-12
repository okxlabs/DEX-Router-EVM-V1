// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/RingAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        console2.log("deployer", deployer);
        require(
            deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97,
            "wrong deployer! change the private key"
        );

        vm.createSelectFork(vm.envString("BLAST_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 81457, "must be blast");
        address adapter = address(new RingAdapter());
        console2.log("RingAdapter deployed: %s", adapter);
        vm.stopBroadcast();
    }
}

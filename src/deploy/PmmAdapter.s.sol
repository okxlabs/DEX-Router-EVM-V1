// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/PmmAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        // require(deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("ARBI_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 42161, "must be ARB");

        address adapter = address(new PMMAdapter());
        console2.log("PmmAdapter deployed eth: %s", adapter);

        vm.stopBroadcast();
    }
}
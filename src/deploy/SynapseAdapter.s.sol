// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SynapseAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0xf1eaf6A40D63E00CFfaf7BdbcbD8A3F62Fb5Ed58, "wrong deployer! change the private key");

        // deploy on basechain
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 8453 , "must be basechain");
      
        address adapter = address(new SynapseAdapter());
        console2.log("SynapseAdapter deployed on base: %s", adapter);

        vm.stopBroadcast();
    }
}

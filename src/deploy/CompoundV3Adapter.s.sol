// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/CompoundV3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0xf1eaf6A40D63E00CFfaf7BdbcbD8A3F62Fb5Ed58, "wrong deployer! change the private key");

        // deploy on ethereum
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1 , "must be eth");
      
        address adapter = address(new CompoundV3Adapter());
        console2.log("CompoundV3 deployed eth: %s", adapter);

        vm.stopBroadcast();
    }
}

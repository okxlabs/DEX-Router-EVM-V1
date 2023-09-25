// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/LevelAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0xf1eaf6A40D63E00CFfaf7BdbcbD8A3F62Fb5Ed58, "wrong deployer! change the private key");

        // // deploy on arbitrim
        // vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        // vm.startBroadcast(deployer);

        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 42161 , "must be arbitrum");
      
        // address adapter = address(new LevelAdapter());
        // console2.log("LevelAdapter deployed on arb: %s", adapter);

        // vm.stopBroadcast();



        //deploy on bsc
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56 , "must be bsc");
      
        address adapter = address(new LevelAdapter());
        console2.log("LevelAdapter deployed on bsc: %s", adapter);

        vm.stopBroadcast();

    }
}

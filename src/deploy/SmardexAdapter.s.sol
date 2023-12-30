// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@dex/adapter/SmardexAdapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

    function run() public {
         deploy_eth();
        // deploy_arb();
        // deploy_base();
        // deploy_bsc();
        // deploy_polygon();
    }

    function deploy_eth() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on eth
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1 , "must be eth");
      
        address adapter = address(new SmardexAdapter());
        console2.log("SmardexAdapter deployed on eth: %s", adapter);

        vm.stopBroadcast();
    }

    function deploy_arb() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on arb
        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 42161 , "must be arb");
      
        address adapter = address(new SmardexAdapter());
        console2.log("SmardexAdapter deployed on arb: %s", adapter);

        vm.stopBroadcast();
    }

    function deploy_base() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on base
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 8453 , "must be base");
      
        address adapter = address(new SmardexAdapter());
        console2.log("SmardexAdapter deployed on base: %s", adapter);

        vm.stopBroadcast();
    }

    function deploy_bsc() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on bsc
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56 , "must be bsc");
      
        address adapter = address(new SmardexAdapter());
        console2.log("SmardexAdapter deployed on bsc: %s", adapter);

        vm.stopBroadcast();
    }

    function deploy_polygon() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on polygon
        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 137 , "must be polygon");
      
        address adapter = address(new SmardexAdapter());
        console2.log("SmardexAdapter deployed on polygon: %s", adapter);

        vm.stopBroadcast();
    }
}

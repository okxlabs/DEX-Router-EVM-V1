// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/TridentAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

    function run() public {
        deploy_avax();
        deploy_arb();
        deploy_bsc();
        deploy_op();
        deploy_polygon();
    }

    function deploy_avax() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("AVAX_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 43114 , "must be avax");
      
        address adapter = address(new TridentAdapter(0x0711B6026068f736bae6B213031fCE978D48E026));
        // https://dev.sushi.com/docs/Products/BentoBox/Deployment%20Addresses
        console2.log("TridentAdapter deployed on avax: %s", adapter);

        vm.stopBroadcast();
        
    }
    function deploy_arb() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 42161 , "must be arb");
      
        address adapter = address(new TridentAdapter(0x74c764D41B77DBbb4fe771daB1939B00b146894A));
        // https://dev.sushi.com/docs/Products/BentoBox/Deployment%20Addresses
        console2.log("TridentAdapter deployed on arb: %s", adapter);

        vm.stopBroadcast();

    }
    function deploy_bsc() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56 , "must be bsc");
      
        address adapter = address(new TridentAdapter(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966));
        // https://dev.sushi.com/docs/Products/BentoBox/Deployment%20Addresses
        console2.log("TridentAdapter deployed on bsc: %s", adapter);

        vm.stopBroadcast();

    }
    function deploy_op() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("OP_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 10 , "must be op");
      
        address adapter = address(new TridentAdapter(0xc35DADB65012eC5796536bD9864eD8773aBc74C4));
        // https://dev.sushi.com/docs/Products/BentoBox/Deployment%20Addresses
        console2.log("TridentAdapter deployed on op: %s", adapter);

        vm.stopBroadcast();

    }
    function deploy_polygon() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 137 , "must be polygon");
      
        address adapter = address(new TridentAdapter(0x0319000133d3AdA02600f0875d2cf03D442C3367));
        // https://dev.sushi.com/docs/Products/BentoBox/Deployment%20Addresses
        console2.log("TridentAdapter deployed on polygon: %s", adapter);

        vm.stopBroadcast();

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@dex/adapter/IntegralAdapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

    function run() public {
        deploy_arb();


    }

    function deploy_arb() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on arb
        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 42161, "must be arb");

        address TWAPRELAY_ADDRESS_ARB = 0x3c6951FDB433b5b8442e7aa126D50fBFB54b5f42;
        address adapter = address(new IntegralAdapter(TWAPRELAY_ADDRESS_ARB));
        console2.log("IntegralAdapter deployed on arb: %s", adapter);

        vm.stopBroadcast();
    }

}

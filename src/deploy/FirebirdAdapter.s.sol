// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@dex/adapter/FirebirdAdapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

    function run() public {
        //deploy_polygon();
        deploy_ftm();
    }

    function deploy_polygon() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 137 , "must be polygon");

        address FIREBIRD_FORMULA_ADDRESS = 0xF8f007970CD7345A6bfF4A0226F50FEEB417378C; //firebird
        address adapter = address(new FirebirdAdapter(FIREBIRD_FORMULA_ADDRESS));
        console2.log("FirebirdAdapter deployed on polygon: %s", adapter);

        vm.stopBroadcast();

    }

    function deploy_ftm() internal {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("FTM_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid ==  250, "must be fantom");

        address FIREBIRD_FORMULA_ADDRESS = 0xbA926938022aEd393436635fEd939cAdf5Afe4D5; //lif3 swap
        address adapter = address(new FirebirdAdapter(FIREBIRD_FORMULA_ADDRESS));
        console2.log("FirebirdAdapter deployed on fantom: %s", adapter);

        vm.stopBroadcast();

    }
}

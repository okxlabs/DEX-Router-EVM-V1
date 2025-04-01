// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/script.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SparkPsmAdapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on BASEchain
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 8453 , "must be BASE");

        address PSM3 = 0x1601843c5E9bC251A3272907010AFa41Fa18347E;//base
        address adapter = address(new SparkPsmAdapter(PSM3));
        console2.log("SparkPsmAdapter deployed on BASE: %s", adapter);

        vm.stopBroadcast();
    }
}

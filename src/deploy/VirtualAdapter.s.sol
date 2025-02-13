// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/script.sol";
import "forge-std/console2.sol";
import "@dex/adapter/VirtualsAdapter.sol";

//virtual internal trading
contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on ARBchain
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 8453 , "must be BASE");
      
        address BONDING = 0xF66DeA7b3e897cD44A5a231c61B6B4423d613259;
        address virtualToken = 0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b;
        address FRouter = 0x8292B43aB73EfAC11FAF357419C38ACF448202C5;
        address adapter = address(new VirtualsAdapter(BONDING, virtualToken, FRouter));
        console2.log("VirtualAdapter deployed on ARB: %s", adapter);

        vm.stopBroadcast();
    }
}

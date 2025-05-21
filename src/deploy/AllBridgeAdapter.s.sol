// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@dex/adapter/AllBridgeAdapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    // address router = 0x609c690e8F7D68a59885c9132e812eEbDaAf0c9e;    // eth
    // address router = 0xE79416E1c4bAe7cdE308aBFF4674052C37481B81;    // arb
    // address router = 0x254CaFe565978A462c0DA8f56C7C2209d6fB1d5e;    // avax
    // address router = 0xd5CC9ccBD4144385ff1f8C75BF66236F1F779c3d;    // op
    address router = 0x5FF960b7E6D6a7c7Cb9E47A455f01AFaCE69BF45;    // polygon

    function run() public {
        require(
            deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad,
            "wrong deployer! change the private key"
        );

        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
        vm.startBroadcast(deployer);

        address adapter = address(new AllBridgeAdapter(router));

        console2.log(
            "AllBridgeAdapter deployed on chian[%s] at[%s]",
            block.chainid,
            adapter
        );
        vm.stopBroadcast();
    }
}

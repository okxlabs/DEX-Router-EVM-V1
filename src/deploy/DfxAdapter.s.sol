// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/ShellAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        console2.log("deployer", deployer);
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("POLY_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        address adapter = address(new ShellAdapter());
        console2.log("ShellAdapter deployed polygon: %s", adapter);
        vm.stopBroadcast();

        vm.createSelectFork(vm.envString("ARBI_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        adapter = address(new ShellAdapter());
        console2.log("ShellAdapter deployed arbitrum: %s", adapter);
        vm.stopBroadcast();
    }
}

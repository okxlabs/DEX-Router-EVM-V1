// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/EchodexAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on mainnet
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 59144, "must be mantle");
        address factory = 0x6D1063F2187442Cc9adbFAD2f55A96B846FCB399;
        address adapter = address(new EchodexAdapter(factory));
        console2.log("EchodexAdapter deployed linea: %s", adapter);

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        address payable WSEI = payable(0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7);
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");
        // deploy on sei
        vm.createSelectFork(vm.envString("SEI_RPC_URL"));
        vm.startBroadcast(deployer);
        require(block.chainid == 1329, "must be sei");

        address adapter = address(new UniV3Adapter(WSEI));
        console2.log("UniV3Adapter deployed sei: %s", adapter);

        vm.stopBroadcast();
    }
}


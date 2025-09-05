// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/FlapAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(
            deployer == 0x0437f3023c2f68dD445e920Ab343E0D1fb390974, 
            "wrong deployer! change the private key"
        );
        address flapPortal = 0xb30D8c4216E1f21F27444D2FfAee3ad577808678; // flap portal on xlayer
        address WNATIVE = 0xe538905cf8410324e03A5A23C1c177a474D59b2b; // WOKB on xlayer
        vm.createSelectFork("xlayer");
        vm.startBroadcast(deployer);
        address adapter = address(new FlapAdapter(flapPortal, WNATIVE));

        console2.log(
            "FlapAdapter deployed on chain[%s] at[%s]",
            block.chainid,
            adapter
        );
        vm.stopBroadcast();
    }
}


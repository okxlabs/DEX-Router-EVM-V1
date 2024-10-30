// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/VirtuSwapAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        
        require(
            deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97,
            "wrong deployer! change the private key"
        );
        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        vm.startBroadcast(deployer);
        address adapter = address(new VirtuSwapAdapter());

        console2.log(
            "VirtuSwapAdapter deployed on chian[%s] at[%s]",
            block.chainid,
            adapter
        );
        vm.stopBroadcast();
    }
}

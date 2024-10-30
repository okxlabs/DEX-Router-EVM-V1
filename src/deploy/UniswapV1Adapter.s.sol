// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/UniswapV1Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        console2.log("deployer", deployer);
        // require(
        //     deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad,
        //     "wrong deployer! change the private key"
        // );

        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        address adapter = address(new UniswapV1Adapter());
        console2.log("UniswapV1Adapter deployed ethereum: %s", adapter);
        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/CompoundV2Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        console2.log("deployer", deployer);
        require(
            deployer == 0x358506b4C5c441873AdE429c5A2BE777578E2C6f,
            "wrong deployer! change the private key"
        );

        // deploy on mainnet
        // vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        // vm.startBroadcast(deployer);
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 1, "must be mainnet");
        // address WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        // address adapter = address(new CompoundAdapter(WETH_MAINNET));
        // console2.log("CompoundAdapter deployed: %s", adapter);
        // vm.stopBroadcast();

        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56, "must be mainnet");
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address adapter = address(new CompoundAdapter(WBNB));
        console2.log("CompoundAdapter deployed: %s", adapter);
        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/OneinchV1Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("DEPLOYER_RPIVATE_KEY"));

    function run() public {
        require(deployer == 0x358506b4C5c441873AdE429c5A2BE777578E2C6f, "wrong deployer! change the private key");

        // deploy on mainnet
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1, "must be mainnet");
        address WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address adapter = address(new OneinchV1Adapter(WETH_MAINNET));
        console2.log("OneinchV1Adapter deployed: %s", adapter);

        // deploy on ZkSync_Era, not supported! should use js script instead
        vm.stopBroadcast();
    }
}

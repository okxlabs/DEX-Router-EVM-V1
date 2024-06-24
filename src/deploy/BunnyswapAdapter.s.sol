// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/BunnyswapAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));


    function run() public {
        require(deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 8453, "must be base");

        address router = 0xBf250AE227De43deDaF01ccBFD8CC83027efc1E2;
        address adapter = address(new BunnyswapAdapter(router));
        console2.log("BunnyswapAdapter deployed base: %s", adapter);

        vm.stopBroadcast();
    }
}
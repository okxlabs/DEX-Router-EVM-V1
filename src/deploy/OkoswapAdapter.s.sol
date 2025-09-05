// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/OkoswapAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 196, "must be xlayer");

        address router = 0x236e11ce039cE0DD079cB356056C9127f65586F9; // OkoSwap Router
        address wokb = 0xe538905cf8410324e03A5A23C1c177a474D59b2b; // Wrapped OKB

        OkoswapAdapter adapter = new OkoswapAdapter(router, wokb);
        console2.log("OkoswapAdapter deployed at:", address(adapter));

        vm.stopBroadcast();
    }
}
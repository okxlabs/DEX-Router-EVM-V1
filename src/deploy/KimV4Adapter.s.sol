// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/KimV4Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("MODE_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 34443, "must be mode");

        address payable WETH = payable(0x4200000000000000000000000000000000000006); //1
        address adapter = address(new KimV4Adapter(WETH));
        console2.log("KimV4Adapter deployed mode: %s", adapter);

        vm.stopBroadcast();
    }
}
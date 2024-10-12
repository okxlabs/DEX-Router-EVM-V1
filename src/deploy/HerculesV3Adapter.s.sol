// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/HerculesV3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));


    function run() public {
        require(deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("METIS_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1088, "must be metis");

        address payable WETH = payable(0x420000000000000000000000000000000000000A); //1
        address adapter = address(new HerculesV3Adapter(WETH));
        console2.log("HerculesV3Adapter deployed metis: %s", adapter);

        vm.stopBroadcast();
    }
}
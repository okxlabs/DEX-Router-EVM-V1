// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/CamelotV3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));


    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("ARBI_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 42161, "must be arbi");

        address payable WETH = payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); //1
        address adapter = address(new CamelotV3Adapter(WETH));
        console2.log("CamelotV3Adapter deployed arbi: %s", adapter);

        vm.stopBroadcast();
    }
}
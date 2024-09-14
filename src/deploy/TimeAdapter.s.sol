// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/TimeAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56, "must be bsc");
        address TIME = 0x13460EAAeaDe9427957F26A570345490b5d7910F;//
        address usd1 = 0x55d398326f99059fF775485246999027B3197955;//BSCUSD-18
        address usd2 = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;//USDC-18
        address usd3 = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;//BUSD-18
        address adapter = address(new TimeAdapter(TIME, usd1, usd2, usd3));
        console2.log("TimeAdapter deployed bsc: %s", adapter);

        vm.stopBroadcast();
    }
}
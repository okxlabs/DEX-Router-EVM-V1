// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/PolygonMigrationAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    address PolygonMigration = 0x29e7DF7b6A1B2b07b731457f499E1696c60E2C4e;
    address POL = 0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6;
    address MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

    function run() public {
        require(deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97, "wrong deployer! change the private key");
        // deploy on eth
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1, "must be eth");

        address adapter = address(new PolygonMigrationAdapter(PolygonMigration, MATIC, POL));
        console2.log("PolygonMigrationAdapter deployed eth: %s", adapter);

        vm.stopBroadcast();
    }
}


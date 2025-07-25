// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/AaveV3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(
            deployer == 0x0437f3023c2f68dD445e920Ab343E0D1fb390974, 
            "wrong deployer! change the private key"
        );
        address aaveV3Pool = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5; // Base Mainnet Address 
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);
        address adapter = address(new AaveV3Adapter(aaveV3Pool));

        console2.log(
            "AaveV3Adapter deployed on chain[%s] at[%s]",
            block.chainid,
            adapter
        );
        vm.stopBroadcast();
    }
}


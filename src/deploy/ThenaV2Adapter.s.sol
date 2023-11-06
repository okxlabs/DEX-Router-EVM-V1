// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@dex/adapter/ThenaV2Adapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    address POOL_DEPLOYER = 0xc89F69Baa3ff17a842AB2DE89E5Fc8a8e2cc7358;
    bytes32 POOL_INIT_CODE_HASH = 0xd61302e7691f3169f5ebeca3a0a4ab8f7f998c01e55ec944e62cfb1109fd2736;

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on BSC
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56, "must be BSC");
      
        address adapter = address(new ThenaV2Adapter(POOL_DEPLOYER, POOL_INIT_CODE_HASH));
        console2.log("ThenaV2Adapter deployed on BSC: %s", adapter);

        vm.stopBroadcast();
    }
}

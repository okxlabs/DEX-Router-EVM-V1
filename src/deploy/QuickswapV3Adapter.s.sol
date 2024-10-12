// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/Quickswapv3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    address WETH = 0x0Dc808adcE2099A9F62AA87D9670745AbA741746;

    function run() public {
        require(deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97, "wrong deployer! change the private key");

        // deploy on manta
        vm.createSelectFork(vm.envString("MANTA_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 169 , "must be manta");
      
        address adapter = address(new Quickswapv3Adapter(payable(WETH)));
        console2.log("Quickswapv3Adapter deployed on manta: %s", adapter);

        vm.stopBroadcast();
    }
}

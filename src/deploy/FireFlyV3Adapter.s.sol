// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "lib/forge-std/src//Script.sol";
import {console2} from "lib/forge-std/src//console2.sol" ;

import "contracts/8//adapter/FireFlyV3Adapter.sol";

contract Deploy is Script {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    address payable WETH = payable (0x0Dc808adcE2099A9F62AA87D9670745AbA741746);
    function run() public {
        
        
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on manta
        vm.createSelectFork(vm.envString("MANTA_RPC_URL"));
        vm.startBroadcast(deployer);

        console2.log("block.chainID", block.chainid);
        require(block.chainid == 169 , "must be manta");
      
        address adapter = address(new FireFlyV3Adapter(WETH));
        console2.log("FireFlyV3Adapter deployed on manta: %s", adapter);

        vm.stopBroadcast();
    }

}
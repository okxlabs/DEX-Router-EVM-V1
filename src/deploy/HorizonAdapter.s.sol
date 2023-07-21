// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/HorizonAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on mainnet
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 59144, "must be linea");
        address factory = 0x9Fe607e5dCd0Ea318dBB4D8a7B04fa553d6cB2c5;
        address payable WETH = payable(0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f); //1
        address adapter = address(new HorizonAdapter(WETH, factory));
        console2.log("HorizonAdapter deployed linea: %s", adapter);

        vm.stopBroadcast();
    }
}

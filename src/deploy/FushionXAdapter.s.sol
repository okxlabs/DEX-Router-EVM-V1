// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/FushionXAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on mainnet
        vm.createSelectFork("https://rpc.mantle.xyz");
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 5000, "must be mantle");
        address payable WMNT = payable(0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8);
        address factoryDeployer = 0x8790c2C3BA67223D83C8FCF2a5E3C650059987b4;
        address adapter = address(new FushionXAdapter(WMNT,factoryDeployer));
        console2.log("FushionXAdapter deployed mantle: %s", adapter);

        vm.stopBroadcast();
    }
}

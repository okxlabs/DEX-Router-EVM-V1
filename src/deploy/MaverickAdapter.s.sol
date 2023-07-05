// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/MaverickAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");

        // deploy on mainnet
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1, "must be mainnet");
        address payable WETH_MAINNET = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        address FACTORY_MAINNET = 0xEb6625D65a0553c9dBc64449e56abFe519bd9c9B;
        address adapter = address(new MaverickAdapter(FACTORY_MAINNET, WETH_MAINNET));
        console2.log("MaverickAdapter deployed mainnet: %s", adapter);

        vm.stopBroadcast();
    }
}

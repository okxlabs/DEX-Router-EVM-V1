// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/PancakeSwapInfinityAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    // BSC Mainnet addresses
    address constant vault = 0x238a358808379702088667322f80aC48bAd5e6c4;
    address constant clPoolManager = 0xa0FfB9c1CE1Fe56963B0321B32E7A0302114058b;
    address constant binPoolManager = 0xC697d2898e0D09264376196696c51D7aBbbAA4a9;
    address payable constant WBNB = payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    function run() public {
        console2.log("deployer", deployer);
        require(
            deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad,
            "wrong deployer! change the private key"
        );

        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 56 , "must be BSC");

        address adapter = address(new PancakeSwapInfinityAdapter(
            IVault(vault),
            WBNB,
            clPoolManager,
            binPoolManager
        ));
        
        console2.log("PancakeSwapInfinityAdapter deployed: %s", adapter);
        console2.log("Vault: %s", vault);
        console2.log("WBNB: %s", WBNB);
        console2.log("CL PoolManager: %s", clPoolManager);
        console2.log("Bin PoolManager: %s", binPoolManager);
        
        vm.stopBroadcast();
    }
} 
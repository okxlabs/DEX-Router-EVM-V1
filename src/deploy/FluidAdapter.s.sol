// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/FluidAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address WETH_ARBI = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address WETH_BASE = 0x4200000000000000000000000000000000000006;

    function run() public {
        console2.log("deployer", deployer);
        require(
            deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad,
            "wrong deployer! change the private key"
        );

        // deployOnEth();
        // deployOnPoly();
        // deployOnArbi();
        deployOnBase();
    }

    function deployOnEth() internal {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        address adapter = address(new FluidAdapter(WETH));
        console2.log("FluidAdapter deployed eth: %s", adapter);
        vm.stopBroadcast();
    }

    function deployOnPoly() internal {
        vm.createSelectFork(vm.envString("POLY_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        address adapter = address(new FluidAdapter(WMATIC));
        console2.log("FluidAdapter deployed polygon: %s", adapter);
        vm.stopBroadcast();
    }

    function deployOnArbi() internal {
        vm.createSelectFork(vm.envString("ARBI_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        address adapter = address(new FluidAdapter(WETH_ARBI));
        console2.log("FluidAdapter deployed arbitrum: %s", adapter);
        vm.stopBroadcast();
    }

    function deployOnBase() internal {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);

        address adapter = address(new FluidAdapter(WETH_BASE));
        console2.log("FluidAdapter deployed base: %s", adapter);
        vm.stopBroadcast();
    }
}

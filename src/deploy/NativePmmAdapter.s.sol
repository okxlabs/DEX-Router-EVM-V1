// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/NativePmmAdapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        // require(
        //     deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97,
        //     "wrong deployer! change the private key"
        // );

        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        vm.startBroadcast(deployer);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 1, "must be ethereum");
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address adapter = address(new NativePmmAdapter(WETH));
        console2.log("NativePmmAdapter deployed ethereum: %s", adapter);

        vm.stopBroadcast();
    }
}

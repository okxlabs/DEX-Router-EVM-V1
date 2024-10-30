// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/NovabitsV3Adapter.sol";

contract Deploy is Test {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(
            deployer == 0xEA522Fe3A65874bA3CEC38e912220282b7C71E97,
            "wrong deployer! change the private key"
        );
        vm.createSelectFork(vm.envString("MANTLE_RPC_URL"));
        vm.startBroadcast(deployer);

        address wrappedNative;
        if (block.chainid == 5000) {
            // Mantle
            wrappedNative = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; //Wrapped Mantle
        } else if (block.chainid == 8453) {
            // Base
            wrappedNative = 0x2798fDe6e53998d7d7D3E34Fa2920aF07412D6d2; //Wrapped Ether
        } else if (block.chainid == 56) {
            // BSC
            wrappedNative = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Wrapped BNB
        } else if (block.chainid == 1) {
            // Ethereum
            wrappedNative = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Wrapped Ether
        } else {
            revert();
        }
        address adapter = address(
            new NovabitsV3Adapter(payable(wrappedNative))
        );

        console2.log(
            "NovabitsV3Adapter deployed on chian[%s] at[%s]",
            block.chainid,
            adapter
        );
        vm.stopBroadcast();
    }
}

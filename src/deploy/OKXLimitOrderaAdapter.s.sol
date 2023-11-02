// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/OKXLimitOrderAdapter.sol";

contract OKXLimitOrderAdapterDeploy is Test {
    address OKXLimitOrderV2 = 0x2ae8947FB81f0AAd5955Baeff9Dcc7779A3e49F2;
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(
            deployer == 0x3A9568f0FEBf99D1EA497Fa9ed22b37ec2f53f47,
            "wrong deployer! change the private key"
        );

        // 1.deploy on arb
        // address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        // address wNativeToken = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        // vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 42161, "must be arb chainId");

        // 2.deploy on avax
        // address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        // address wNativeToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        // vm.createSelectFork(vm.envString("AVAX_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 43114, "must be avax chainId");

        // 3.deploy on bsc
        // address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
        // address wNativeToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        // vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 56, "must be bsc chainId");

        // 4.deploy on eth
        // address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        // address wNativeToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        // vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 1, "must be eth chainId");

        // 5.deploy on ftm
        // address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        // address wNativeToken = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        // vm.createSelectFork(vm.envString("FTM_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 250, "must be ftm chainId");

        // 6.deploy on okc
        // address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        // address wNativeToken = 0x8F8526dbfd6E38E3D8307702cA8469Bae6C56C15;
        // vm.createSelectFork(vm.envString("OKC_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 66, "must be okc chainId");

        // 7.deploy on op
        // address tokenApprove = 0x68D6B739D2020067D1e2F713b999dA97E4d54812;
        // address wNativeToken = 0x4200000000000000000000000000000000000006;
        // vm.createSelectFork(vm.envString("OP_RPC_URL"));
        // console2.log("block.chainID", block.chainid);
        // require(block.chainid == 10, "must be op chainId");

        // 8.deploy on polygon
        address tokenApprove = 0x3B86917369B83a6892f553609F3c2F439C184e31;
        address wNativeToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 137, "must be polygon chainId");

        vm.startBroadcast(deployer);
        address adapter = address(
            new OKXLimitOrderAdapter(
                OKXLimitOrderV2,
                tokenApprove,
                wNativeToken
            )
        );
        console2.log("OKXLimitOrderAdapter deployed: %s", adapter);
        vm.stopBroadcast();
    }
}

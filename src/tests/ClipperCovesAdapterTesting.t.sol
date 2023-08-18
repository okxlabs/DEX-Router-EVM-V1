pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/ClipperCovesAdapter.sol";
import "@dex/interfaces/IAdapter.sol";
import "@dex/interfaces/IERC20.sol";


contract ClipperCovesAdapterTesting is Test {
    ClipperCovesAdapter adapter;
    
    // SUSD -> SNX
    function test_op() public {
        vm.createSelectFork(vm.envString("OP_RPC_URL"));
        address SUSD = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;
        address SNX = 0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4;
        address POOL = 0x93baB043d534FbFDD13B405241be9267D393b827;
        adapter = new ClipperCovesAdapter();

        vm.startPrank(0xe3e752B04adeD62E3f0D51f7425E558b15E6aA67);
        IERC20(SUSD).transfer(POOL, 100*10**18);

        bytes memory moreInfo = abi.encode(SUSD, SNX);
        adapter.sellBase(address(this), POOL, moreInfo);
        console2.log(IERC20(SNX).balanceOf(address(this)));
    }

    function test_polygon() public {
        address POOL =  0x2370cB1278c948b606f789D2E5Ce0B41E90a756f;
    }

    function test_moonbeam() public {
        address POOL = 0x3309a431de850Ec554E5F22b2d9fC0B245a2023e;
    }
}

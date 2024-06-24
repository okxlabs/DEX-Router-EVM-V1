pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import {BunnyswapAdapter, IERC20} from "@dex/adapter/BunnyswapAdapter.sol";

contract BunnyswapAdapterTest is Test {
    BunnyswapAdapter public adapter;
    address payable WETH = payable(0x4200000000000000000000000000000000000006);
    address FRIEND = 0x0bD4887f7D41B35CD75DFF9FfeE2856106f86670;
    address router = 0xBf250AE227De43deDaF01ccBFD8CC83027efc1E2;

    function setUp0() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 15945099);
    }

    function setUp() public {
        setUp0();
        adapter = new BunnyswapAdapter(router); 
        deal(WETH, address(this), 0.4*10**18);
    }

    function test_adapter() public {
        IERC20(WETH).transfer(address(adapter), 400000000000000000);
        //FRIEND.call(abi.encodeWithSignature("transfer(address,uint256)", address(adapter), 1000000000000000000));
        IERC20(WETH).balanceOf(address(adapter));
        adapter.sellQuote(address(this), router, abi.encode(0.4*10**18, 1990060297433005341162));
        console2.log("FRIEND amount", IERC20(FRIEND).balanceOf(address(this)));
    }
}
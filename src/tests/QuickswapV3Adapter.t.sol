pragma solidity 0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import {Quickswapv3Adapter, IERC20} from "@dex/adapter/Quickswapv3Adapter.sol";

contract quickswapV3Test is Test {
    
    address payable WETH = payable(0x0Dc808adcE2099A9F62AA87D9670745AbA741746);
    address USDC = 0xb73603C5d87fA094B7314C74ACE2e64D165016fb;
    address pool = 0x12CdDeD759B14bf6A34FbF6638aec9B735824a9E;

    Quickswapv3Adapter adapter;

    function setUp0() public {
        vm.createSelectFork(vm.envString("MANTA_RPC_URL"));
    }

    function setUp() public {
        setUp0();
        adapter = new Quickswapv3Adapter(WETH);
        deal(USDC, address(this), 100 * 10 ** 6);
        deal(WETH, address(this), 1 ether);
    }

    function test_1() public {
        USDC.call(abi.encodeWithSignature("transfer(address,uint256)", address(adapter), 10 * 10 ** 6));
        adapter.sellQuote(address(this), pool, abi.encode(0, abi.encode(USDC, WETH)));
        console2.log("WETH amount", IERC20(WETH).balanceOf(address(this)) - 1 ether);
    }
}

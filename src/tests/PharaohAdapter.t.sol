pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/SolidlyseriesAdapter.sol";

contract SolidlyseriesAdapterTest is Test {
    SolidlyseriesAdapter adapter;
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address PHARWAVAX = 0xAAA3f202BAbcf7d6493aFBc0CaeE03AF9C64f984;
    address PHAR = 0xAAAB9D12A30504559b0C5a9A5977fEE4A6081c6b;

    function setUp() public {
        vm.createSelectFork(vm.envString("AVAX_RPC_URL"));
        adapter = new SolidlyseriesAdapter();
        //adapter = new SolidlyV3Adapter();
        deal(WAVAX, address(this), 1 * 10 ** 18);
    }

    function test_1() public {
        console2.log("PHAR beforeswap balance", IERC20(PHAR).balanceOf(address(this)));
        IERC20(WAVAX).transfer(PHARWAVAX, 0.1 * 10 ** 18);
        bytes memory moreInfo = "0x";
        adapter.sellQuote(address(this), PHARWAVAX, moreInfo);
        console2.log("PHAR afterswap balance", IERC20(PHAR).balanceOf(address(this)));
    }
}
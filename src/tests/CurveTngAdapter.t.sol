pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/CurveTNGAdapter.sol";

contract CurveTngAdaterTest is Test {
    CurveTNGAdapter adapter;
    // USDT-WBTC-WETH
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address pool = 0xf5f5B97624542D72A9E06f04804Bf81baA15e2B4;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 17418514);
        adapter = new CurveTNGAdapter();
        WETH.call{value: 100 ether}("");
    }

    function test_1() public {
        IERC20(WETH).transfer(address(adapter), 100 ether);
        bytes memory moreInfo = abi.encode(WETH, USDT, uint256(2), uint256(0));
        adapter.sellBase(address(this), pool, moreInfo);
        console2.log("USDT balance", IERC20(USDT).balanceOf(address(this)));
    }
}

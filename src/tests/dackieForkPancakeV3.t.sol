pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/PancakeswapV3Adapter.sol";


contract PancakeswapV3AdapterTest is Test {

    PancakeswapV3Adapter adapter;
    address DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address DACKIE = 0xc2BC7A73613B9bD5F373FE10B55C59a69F4D617B;
    // address pancakeFactory = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
    // it's the dackieV3factory that should be used
    address dackieFactory = 0x3D237AC6D2f425D2E890Cc99198818cc1FA48870;
    address WETH = 0x4200000000000000000000000000000000000006;
    address DAIUSDbC = 0x79524e3BBCA7263593800F9b30D3CbFE00478c31;
    address DACKIEWETH = 0x88cef98B0B3bc675d1Ed53c34EB239c6C4BF99ef;

    function test_DAItoUSDbC() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3638730);
        adapter = new PancakeswapV3Adapter(payable(WETH), dackieFactory);
        deal(DAI, address(this), 1 * 10**18);
        // tx: https://basescan.org/tx/0xa8607b9c5e60b84634240c0aecde245cb828e3ea4666bb461a152ca89f547214
        IERC20(DAI).transfer(address(adapter), 144366098795641491);
        uint160 sqrtPriceLimitX96 = 4295128740;
        // pool created: https://basescan.org/tx/0x1f677b1632e6dc572a013d435bac1225c3e086cd669ab18bd246e338653f7234#eventlog
        bytes memory data = abi.encode(DAI, USDbC, uint24(500));
        bytes memory moreInfo = abi.encode(sqrtPriceLimitX96, data);
        adapter.sellBase(address(this), DAIUSDbC, moreInfo);
        console2.log("USDbC", IERC20(USDbC).balanceOf(address(this)));
    }

    function test_DACKIEtoWETH() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3684657);
        adapter = new PancakeswapV3Adapter(payable(WETH), dackieFactory);
        deal(DACKIE, address(this), type(uint128).max);
        // tx: https://basescan.org/tx/0xad49e374ea20c1b9a98921ebaf0b9397a592b6fa3db2763364c4cbb2c86efdf5
        IERC20(DACKIE).transfer(address(adapter), 19802033549441424750);
        uint160 sqrtPriceLimitX96 = 1461446703485210103287273052203988822378723970341;
        // pool created: https://basescan.org/tx/0xf8a349bba78361114d8a81d28b5de905a1e12d525c9ec103aa0032a595f57922#eventlog
        bytes memory data = abi.encode(DACKIE, WETH, uint24(2500));
        bytes memory moreInfo = abi.encode(sqrtPriceLimitX96, data);
        adapter.sellBase(address(this), DACKIEWETH, moreInfo);
        console2.log("WETH", IERC20(WETH).balanceOf(address(this)));
    }


}
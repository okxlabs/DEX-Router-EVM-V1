pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/PancakeswapV3Adapter.sol";

contract RevoSwapV3AdapterTest is Test {

    PancakeswapV3Adapter adapter;
    address payable WOKB = payable(0xe538905cf8410324e03A5A23C1c177a474D59b2b);
    address USDT = 0x1E4a5963aBFD975d8c9021ce480b42188849D41d;
    address USDTWOKB = 0xF3b755FB1C3486c3878B1539c594B9e619a51995;
    address factory = 0x47CdeCafBA3960588d79a328c725c3529d4eC081;

    function test_WOKBtoUSDT() public {
        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"));
        adapter = new PancakeswapV3Adapter(WOKB, factory);
        deal(USDT, address(this), 1 * 10 ** 6);
        IERC20(USDT).transfer(address(adapter), 1 * 10 ** 6);
        uint160 sqrtPriceLimitX96 = 0.01 * 10 ** 18;
        bytes memory data = abi.encode(USDT, WOKB, uint24(2500));
        bytes memory moreInfo = abi.encode(sqrtPriceLimitX96, data);
        adapter.sellBase(address(this), USDTWOKB, moreInfo);
        console2.log("WOKB", IERC20(WOKB).balanceOf(address(this)));
    }
}
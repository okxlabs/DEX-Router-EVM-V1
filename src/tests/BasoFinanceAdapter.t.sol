pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/SolidlyseriesAdapter.sol";

/// @title BasoFinanceUniTest
/// @notice BasoFinance belongs to solidlyseries, do the usability test of former adapter
/// @dev Explain to a developer any extra details

contract BasoReuseSolidlySeriesTest is Test {
    SolidlyseriesAdapter adapter;
    address DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address WETH = 0x4200000000000000000000000000000000000006;

    address WethUsdbc = 0xE1ADA5ACb1759b3159c9d2D0ff9d6a3BbFE775D7;
    address DaiUsdbc = 0x0363A56C52572BC6bC63A34473c95500a845ae8e;

    function test_stable() public {
        // compared tx : https://basescan.org/tx/0x6582948b4574ae948324fdd294e90e5c1eae61822bc19e056f4517f94f0c22fe
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 4156794);
        adapter = new SolidlyseriesAdapter();
        deal(DAI, address(this), 2 * 10**18);
        IERC20(DAI).transfer(DaiUsdbc, 1 * 10**18);
        console2.log("Before: Dai USDbc", IERC20(DAI).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
        adapter.sellBase(address(this), DaiUsdbc, "0x");
        console2.log("After: Dai USDbc", IERC20(DAI).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
    }

    function test_volatile() public {
        // compared tx : https://basescan.org/tx/0xcb1e613638333588aebbd61fb01e279f28dc7d8b112c15c4c2fcba5a0d18373d
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 4189824);
        adapter = new SolidlyseriesAdapter();
        deal(WETH, address(this), 1 ether);
        IERC20(WETH).transfer(WethUsdbc, 0.005 ether);
        console2.log("Before: WETH USDbc", IERC20(WETH).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
        adapter.sellBase(address(this), WethUsdbc, "0x");
        console2.log("After: WETH USDbc", IERC20(WETH).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
    }

}
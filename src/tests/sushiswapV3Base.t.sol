pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";

/// @title sushiV3BaseTest
/// @notice do the usability test of former uniV3 adapter on Base for sushiswapV3
/// @dev Explain to a developer any extra details
contract sushiV3BaseTest is Test {

    UniV3Adapter adapter;
    address WETH = 0x4200000000000000000000000000000000000006;
    address DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address axlUSDC = 0xEB466342C4d449BC9f53A865D5Cb90586f405215;

    address WETHDAI = 0x4D734eAF2102407825f45571D51FC7C4DaE86fF8;
    address USDbCaxlUSDC = 0x966053115156A8279a986ed9400AC602fB2f5800;

    function test_WETHtoDAI() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3764787);
        adapter = new UniV3Adapter(payable(WETH));
        deal(WETH, address(this), 1 ether);
        IERC20(WETH).transfer(address(adapter), 0.001 * 10**18);
        // tx: https://basescan.org/tx/0x25302b19276416265fc5a94eb7c8d0b7b0e25af93cdde11313801cdd4de30627
        uint160 sqrtX96 = 4295128740;
        // pool info: https://basescan.org/tx/0x69e35483fde0d737868e5712bd94accae50d604c8d1efeeede42e104a8db1ed3#eventlog
        bytes memory data = abi.encode(WETH, DAI, uint24(3000));
        bytes memory moreInfo = abi.encode(sqrtX96, data);
        adapter.sellBase(address(this), WETHDAI, moreInfo);
        console2.log("DAI", IERC20(DAI).balanceOf(address(this)));
    }

    function test_USDbCtoaxlUSDC() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3773817);
        adapter = new UniV3Adapter(payable(WETH));
        deal(USDbC, address(this), 1 * 10**6);
        IERC20(USDbC).transfer(address(adapter), 0.1 * 10**6);
        // tx: https://basescan.org/tx/0x30429c6923a23d639f0d289ee811e84f22b7cdbada4b8718a53e6983eaa44203
        uint160 sqrtX96 = 4295128740;
        // pool info: https://basescan.org/tx/0xcd221a05ba15515a2e06b4ecb07e5cd7bf7329fe31664542bc90be8481628eb5#eventlog
        bytes memory data = abi.encode(USDbC, axlUSDC, uint24(500));
        bytes memory moreInfo = abi.encode(sqrtX96, data);
        adapter.sellBase(address(this), USDbCaxlUSDC, moreInfo);
        console2.log("axlUSDC", IERC20(axlUSDC).balanceOf(address(this)));    
    }

}
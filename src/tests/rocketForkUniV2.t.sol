pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/DnyFeeAdapter.sol";

/// @title rocketForkUniTest
/// @notice rocketswap on Base forks uniV2, do the usability test of former dnyAdapter
/// @dev Explain to a developer any extra details
contract rocketForkUniTest is Test {

    DnyFeeAdapter adapter;
    address WETH = 0x4200000000000000000000000000000000000006;
    address RCKT = 0x6653dD4B92a0e5Bf8ae570A98906d9D6fD2eEc09;
    address axlUSDC = 0xEB466342C4d449BC9f53A865D5Cb90586f405215;

    address RCKTaxlUSDC = 0x1a7975836BD4f1a53e5251F41b6DA5FF5FD105f5;
    address axlUSDCWETH = 0x86cd8533b0166BDcF5d366A3Bb0c3465E56D3ad5;

    function test_RCKTtoaxlUSDC() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3781130);
        adapter = new DnyFeeAdapter();
        deal(RCKT, address(this), 10 * 10**18);
        IERC20(RCKT).transfer(address(RCKTaxlUSDC), 2 * 10**18);
        // tx: https://basescan.org/tx/0x58d6b6e915bec61d737c3c4311cd4aedc9e5434f8e9804a0d1614b5314fef9c5
        // fee: 3/1000
        bytes memory moreInfo = abi.encode(uint256(30));
        adapter.sellBase(address(this), RCKTaxlUSDC, moreInfo);
        console2.log("axlUSDC", IERC20(axlUSDC).balanceOf(address(this)));
    }

    function test_axlUSDCtoWETH() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 3802311);
        adapter = new DnyFeeAdapter();
        deal(axlUSDC, address(this), 1 * 10**6);
        IERC20(axlUSDC).transfer(address(axlUSDCWETH), 0.1 * 10**6);
        // tx: https://basescan.org/tx/0x5c9777c05d10055f8315944bae54f3ebf3733df315c4f74f7354182742acbc8d
        // fee: 3/1000
        bytes memory moreInfo = abi.encode(uint256(30));
        adapter.sellQuote(address(this), axlUSDCWETH, moreInfo);
        console2.log("WETH", IERC20(WETH).balanceOf(address(this)));
    }


}
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/KyberElasticAdapter.sol";

/// @title KyberElastic UniTest
/// @notice Do the usability test of KyberElastic adapter on Base
/// @dev Explain to a developer any extra details

contract KyberElasticAdapterTest is Test {
    KyberElasticAdapter adapter;
    address DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address WETH = 0x4200000000000000000000000000000000000006;

    address DaiUsdbc = 0xC4b88B97c526B3312C4138C3E68f4b9B52E2B139;
    address WethUsdbc = 0x504fE150Bd2fA3e1F7F68Ad2B5a8E901b713dC7f;

    function test_01() public {
        // compared tx : https://basescan.org/tx/0x8ff1b938771f3bcbb702170e8b0645ea0d8e9cc9d049827fe50499c1188b9ad0
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 4191972);
        adapter = new KyberElasticAdapter(payable(WETH));
        deal(DAI, address(this), 2 * 10**18);
        IERC20(DAI).transfer(address(adapter), 2 * 10**18);
        console2.log("Before: Dai USDbc", IERC20(DAI).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
        bytes memory data = abi.encode(DAI, USDbC, uint24(0));
        adapter.sellBase(address(this), DaiUsdbc, abi.encode(uint160(0), data));
        console2.log("After: Dai USDbc", IERC20(DAI).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
    }

    function test_02() public {
        // compared tx : https://basescan.org/tx/0xf907c94daa570a14940d1e28307bb59346424458b5bd3571b7604de295a0875c
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 4192662);
        adapter = new KyberElasticAdapter(payable(WETH));
        deal(WETH, address(this), 1 ether);
        IERC20(WETH).transfer(address(adapter), 0.001 ether);
        console2.log("Before: WETH USDbc", IERC20(WETH).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
        bytes memory data = abi.encode(WETH, USDbC, uint24(0));
        adapter.sellBase(address(this), WethUsdbc, abi.encode(uint160(0), data));
        console2.log("After: WETH USDbc", IERC20(WETH).balanceOf(address(this)), IERC20(USDbC).balanceOf(address(this)));
    }
}
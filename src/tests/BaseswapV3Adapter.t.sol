pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";

/// @title BaseswapV3 UniTest
/// @notice BaseswapV3 forks UniswapV3, do the usability test of former adapter
/// @dev Explain to a developer any extra details

contract BaseswapV3ReuseTest is Test {
    UniV3Adapter adapter;
    address DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address WETH = 0x4200000000000000000000000000000000000006;
    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address UsdbcWeth = 0xEf3C164b0feE8Eb073513E88EcEa280A58cC9945;
    address UsdbcUsdc = 0x88492051E18a65FE00241A93699A6082aE95c828;

    function test_01() public {
        // compared tx : https://basescan.org/tx/0xe89bceb6e8c90130e79b49d7e867743968f9258f92eac991278c09c12dcfc301
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 4233445);
        adapter = new UniV3Adapter(payable(WETH));
        deal(USDbC, address(this), 1 * 10**6);
        IERC20(USDbC).transfer(address(adapter), 1 * 10**6);
        console2.log("Before: USDbc WETH", IERC20(USDbC).balanceOf(address(this)), IERC20(WETH).balanceOf(address(this)));
        bytes memory data = abi.encode(USDbC, WETH, uint24(0));
        adapter.sellBase(address(this), UsdbcWeth, abi.encode(uint160(3190326178310409524064381), data));
        console2.log("After: USDbc WETH", IERC20(USDbC).balanceOf(address(this)), IERC20(WETH).balanceOf(address(this)));
    }

    function test_02() public {
        // compared tx : https://basescan.org/tx/0x5182f3634ee541abc4ee01e4094d5dd8a505bd003bbfddb2c70d112ad62c870a
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), 4234265);
        adapter = new UniV3Adapter(payable(WETH));
        deal(USDbC, address(this), 1 * 10**6);
        IERC20(USDbC).transfer(address(adapter), 1 * 10**6);
        console2.log("Before: USDbc USDC", IERC20(USDbC).balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)));
        bytes memory data = abi.encode(USDbC, USDC, uint24(0));
        adapter.sellBase(address(this), UsdbcUsdc, abi.encode(uint160(79242158252413910986720575324), data));
        console2.log("After: USDbc USDC", IERC20(USDbC).balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)));
    }

}
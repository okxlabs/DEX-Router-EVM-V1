pragma solidity 0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/MooniswapAdapter.sol";

contract MooniswapTest is Test {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address pool = 0x61Bb2Fda13600c497272A8DD029313AfdB125fd3;
    MooniswapAdapter adapter;

    function test_USDCtoETH() public {
        vm.createSelectFork(
            "https://rpc.ankr.com/eth", bytes32(0x471a99ab7e6f102216af2236768b4844a164b9a95496f95701fa3fedc8aba740)
        );
        adapter = new MooniswapAdapter(WETH);
        address user = 0x8D71eAf641F728AdB29D6353FAB85C74DCc30Ad2;
        uint256 amount = 402492779;
        vm.startPrank(user);
        uint256 amountBefore = IERC20(WETH).balanceOf(address(user));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(user)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(user)));
        IERC20(USDC).transfer(address(adapter), amount);

        adapter.sellBase(user, pool, abi.encode(USDC, ETH_ADDRESS));

        uint256 amountAfter = IERC20(WETH).balanceOf(address(user));

        require(amountAfter - amountBefore == 0.304100533280736527 ether, "not ok");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(user)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(user)));
    }

    function test_ETHtoUSDC() public {
        vm.createSelectFork(
            "https://rpc.ankr.com/eth", bytes32(0x18d52a930bcced605d374fae008b4ab09ab853e06d0fb2cf6fb6a7dcb22018b7)
        );
        adapter = new MooniswapAdapter(WETH);
        address user = 0xAcD7f2c7221c35Ff0Ab461D96485180C645bF696;
        uint256 amount = 0.0001 ether;
        vm.startPrank(user);
        uint256 amountBefore = IERC20(USDC).balanceOf(address(user));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(user)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(user)));
        IWETH(WETH).deposit{value: amount}();
        IERC20(WETH).transfer(address(adapter), amount);

        adapter.sellBase(user, pool, abi.encode(ETH_ADDRESS, USDC));

        uint256 amountAfter = IERC20(USDC).balanceOf(address(user));

        require(amountAfter - amountBefore == 153713, "not ok");
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(user)));
        console2.log("USDC balance", IERC20(USDC).balanceOf(address(user)));
    }
}

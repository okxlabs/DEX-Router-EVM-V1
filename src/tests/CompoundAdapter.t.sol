pragma solidity 0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/CompoundV2Adapter.sol";

contract comp is Test {
    address cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address cETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function test_mintEth() public {
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"), bytes32(0x08dcecac14fd6ef7195fa3e1df654b802538a8caad3f45fe6ef7fe1f0f776291)
        );
        CompoundAdapter adapter = new CompoundAdapter(WETH);
        address user = 0x0000000000000000001100000000000000000000;
        vm.deal(user, 10 ether);

        console2.log("cETH balance", IERC20(cETH).balanceOf(user));
        console2.log("ETH balance", address(user).balance);

        vm.startPrank(user);
        IWETH(WETH).deposit{value: 10 ether}();
        IWETH(WETH).transfer(address(adapter), 10 ether);
        adapter.sellBase(user, address(0), abi.encode(ETH_ADDRESS, cETH, true));

        console2.log("cETH balance", IERC20(cETH).balanceOf(user));
        console2.log("ETH balance", address(user).balance);
    }

    function test_redeemEth() public {
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"), bytes32(0x08dcecac14fd6ef7195fa3e1df654b802538a8caad3f45fe6ef7fe1f0f776291)
        );
        CompoundAdapter adapter = new CompoundAdapter(WETH);
        address user = 0x0000000000000000001100000000000000000000;
        vm.deal(user, 10 ether);
        vm.startPrank(user);
        IWETH(WETH).deposit{value: 10 ether}();
        IWETH(WETH).transfer(address(adapter), 10 ether);
        adapter.sellBase(user, address(0), abi.encode(ETH_ADDRESS, cETH, true));
        console2.log("cETH balance", IERC20(cETH).balanceOf(user));
        console2.log("WETH balance", IERC20(WETH).balanceOf(user));

        IWETH(cETH).transfer(address(adapter), IERC20(cETH).balanceOf(user));
        adapter.sellQuote(user, address(0), abi.encode(cETH, ETH_ADDRESS, false));

        console2.log("cETH balance", IERC20(cETH).balanceOf(user));
        console2.log("WETH balance", IERC20(WETH).balanceOf(user));
    }

    function test_mintUSDT() public {
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"), bytes32(0x08dcecac14fd6ef7195fa3e1df654b802538a8caad3f45fe6ef7fe1f0f776291)
        );
        CompoundAdapter adapter = new CompoundAdapter(WETH);
        address user = 0x0000000000000000001100000000000000000000;
        vm.deal(user, 10 ether);
        deal(USDT, user, 10 * 1e6);

        console2.log("cUSDT balance", IERC20(cUSDT).balanceOf(user));
        console2.log("USDT balance", IERC20(USDT).balanceOf(user));

        vm.startPrank(user);
        SafeERC20.safeTransfer(IERC20(USDT), address(adapter), 10 * 1e6);
        adapter.sellBase(user, address(0), abi.encode(USDT, cUSDT, true));

        console2.log("cUSDT balance", IERC20(cUSDT).balanceOf(user));
        console2.log("USDT balance", IERC20(USDT).balanceOf(user));
    }

    function test_redeemUSDT() public {
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"), bytes32(0x08dcecac14fd6ef7195fa3e1df654b802538a8caad3f45fe6ef7fe1f0f776291)
        );
        CompoundAdapter adapter = new CompoundAdapter(WETH);
        address user = 0x0000000000000000001100000000000000000000;
        vm.deal(user, 10 ether);
        deal(cUSDT, user, 10 * 1e6);

        console2.log("cUSDT balance", IERC20(cUSDT).balanceOf(user));
        console2.log("USDT balance", IERC20(USDT).balanceOf(user));

        vm.startPrank(user);
        IERC20(cUSDT).transfer(address(adapter), 10 * 1e6);
        adapter.sellBase(user, address(0), abi.encode(cUSDT, USDT, false));

        console2.log("cUSDT balance", IERC20(cUSDT).balanceOf(user));
        console2.log("USDT balance", IERC20(USDT).balanceOf(user));
    }
}

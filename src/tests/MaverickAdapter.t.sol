pragma solidity 0.8.12;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/MaverickAdapter.sol";

contract MaverickAdapterTest is Test {
    MaverickAdapter adapter;
    address payable WETH = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDC_FRAX = 0xccB606939387C0274AAA2426517Da315C1154e50;
    address WETH_USDT = 0x352B186090068Eb35d532428676cE510E17AB581;

    address router = 0x3b3ae790Df4F312e745D270119c6052904FB6790;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 17567723);
        adapter = new MaverickAdapter(0xEb6625D65a0553c9dBc64449e56abFe519bd9c9B, WETH);
    }

    function test_1() public {
        deal(USDC, address(this), 10 ** 6);
        IERC20(USDC).transfer(address(adapter), 10 ** 6);

        adapter.sellBase(address(this), USDC_FRAX, abi.encode(USDC, FRAX));
        console2.log("FRAX", IERC20(FRAX).balanceOf(address(this)));
    }

    function test_2() public {
        deal(FRAX, address(this), 1 ether);
        IERC20(FRAX).transfer(address(adapter), 1 ether);

        adapter.sellBase(address(this), USDC_FRAX, abi.encode(FRAX, USDC));
        console2.log("USDC", IERC20(USDC).balanceOf(address(this)));
    }

    function test_3() public {
        deal(WETH, address(this), 1 ether);

        IERC20(WETH).transfer(address(adapter), 1 ether);

        adapter.sellBase(address(this), WETH_USDT, abi.encode(WETH, USDT));
        console2.log("USDT", IERC20(USDT).balanceOf(address(this)));
    }

    function test_4() public {
        deal(USDT, address(this), 10 ** 6);

        SafeERC20.safeTransfer(IERC20(USDT), address(adapter), 10 ** 6);
        adapter.sellBase(address(this), WETH_USDT, abi.encode(USDT, WETH));
        console2.log("WETH", IERC20(WETH).balanceOf(address(this)));
    }

    // function test_5() public {
    //     deal(WETH, address(this), 1 ether);

    //     IERC20(WETH).transfer(address(adapter), 1 ether);

    //     adapter.sellBase(address(this), WETH_USDT, abi.encode(ETH_ADDRESS, USDT));
    //     console2.log("USDT", IERC20(USDT).balanceOf(address(this)));
    // }

    // function test_6() public {
    //     deal(USDT, address(this), 10 ** 6);

    //     SafeERC20.safeTransfer(IERC20(USDT), address(adapter), 10 ** 6);
    //     adapter.sellBase(address(this), WETH_USDT, abi.encode(USDT, ETH_ADDRESS));
    //     console2.log("WETH", IERC20(WETH).balanceOf(address(this)));
    // }
}

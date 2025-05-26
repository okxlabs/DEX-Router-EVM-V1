// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/HerculesV3Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract HerculesV3UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x06f183D52D92c13a5f2B989B8710BA7F00bd6f87));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address payable WETH = payable(0x420000000000000000000000000000000000000A); // decimals: 18
    address USDC = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address WETH_USDC = 0x35096c3cA17D12cBB78fA4262f3c6eff73ac9fFc;

    HerculesV3Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("METIS_RPC_URL"), 20467016);
        customAdapter = new HerculesV3Adapter(WETH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_herculesV3_swapUSDTtoUSDC_customAdapter() public {
        deal(WETH, address(this), 1 * 10 ** 16);
        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(this))); 
        IERC20(WETH).transfer(address(customAdapter), 1 * 10 ** 16);
        customAdapter.sellBase(address(this), WETH_USDC, abi.encode(0, abi.encode(WETH, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_herculesV3_swapUSDTtoUSDC_universalAdapter() public {
        deal(WETH, address(this), 1 * 10 ** 16);
        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(this))); 
        IERC20(WETH).transfer(address(universalAdapter), 1 * 10 ** 16);
        universalAdapter.sellBase(address(this), WETH_USDC, abi.encode(0, abi.encode(WETH, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

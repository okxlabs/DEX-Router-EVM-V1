// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/PancakeswapV3Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract PancakeswapV3UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x06f183D52D92c13a5f2B989B8710BA7F00bd6f87));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address factoryAddr = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
    address payable WETH = payable (0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f);
    address USDC = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address USDC_WETH = 0xd5539D0360438a66661148c633A9F0965E482845;

    PancakeswapV3Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 19239890);
        customAdapter = new PancakeswapV3Adapter(WETH, factoryAddr);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_pancakeswapV3_swapWETHtoUSDC_customAdapter() public {
        deal(WETH, address(this), 1 * 10 ** 16);
        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(this))); 
        IERC20(WETH).transfer(address(customAdapter), 1 * 10 ** 16);
        customAdapter.sellBase(address(this), USDC_WETH, abi.encode(0, abi.encode(WETH, USDC, 500)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_pancakeswapV3_swapWETHtoUSDC_universalAdapter() public {
        deal(WETH, address(this), 1 * 10 ** 16);
        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(this))); 
        IERC20(WETH).transfer(address(universalAdapter), 1 * 10 ** 16);
        universalAdapter.sellBase(address(this), USDC_WETH, abi.encode(0, abi.encode(WETH, USDC, 500)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

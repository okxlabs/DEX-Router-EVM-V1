// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/RamsesV2Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract RamsesV2UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address payable WETH = payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); 
    address YFX = 0xaaE0c3856e665ff9b3E2872B6D75939D810b7E40;
    address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address YFX_USDC = 0x2C07608f46867163D6C4ae2c102e28846686799B;

    RamsesV2Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ARBI_RPC_URL"), 338809764);
        customAdapter = new RamsesV2Adapter(WETH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_ramsesV2_swapYFXtoUSDC_customAdapter() public {
        deal(YFX, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(YFX).balanceOf(address(this))); 
        IERC20(YFX).transfer(address(customAdapter), 1 * 10 ** 18);
        customAdapter.sellBase(address(this), YFX_USDC, abi.encode(0, abi.encode(YFX, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_ramsesV2_swapYFXtoUSDC_universalAdapter() public {
        deal(YFX, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(YFX).balanceOf(address(this))); 
        IERC20(YFX).transfer(address(universalAdapter), 1 * 10 ** 18);
        universalAdapter.sellBase(address(this), YFX_USDC, abi.encode(0, abi.encode(YFX, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

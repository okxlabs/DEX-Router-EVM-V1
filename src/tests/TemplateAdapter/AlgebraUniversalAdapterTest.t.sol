// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/AlgebraAdapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract AlgebraUniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0xD321ab5589d3E8FA5Df985ccFEf625022E2DD910;

    address payable WS = payable(0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38); 
    address USDC = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;
    address stS = 0xE5DA20F15420aD15DE0fa650600aFc998bbE3955;

    address USDC_stS = 0x5DDbeF774488cc68266d5F15bFB08eaA7cd513F9;

    AlgebraAdapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 28891140);
        customAdapter = new AlgebraAdapter(WS);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WS), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_algebra_swapUSDCtostS_customAdapter() public {
        deal(USDC, address(this), 1 * 10 ** 6);
        console2.log("fromToken balance before", IERC20(USDC).balanceOf(address(this))); 
        IERC20(USDC).transfer(address(customAdapter), 1 * 10 ** 6);
        customAdapter.sellBase(address(this), USDC_stS, abi.encode(0, abi.encode(USDC, stS)));
        console2.log("toToken balance after", IERC20(stS).balanceOf(address(this)));
    }

    function test_algebra_swapUSDCtostS_universalAdapter() public {
        deal(USDC, address(this), 1 * 10 ** 6);
        console2.log("fromToken balance before", IERC20(USDC).balanceOf(address(this))); 
        IERC20(USDC).transfer(address(universalAdapter), 1 * 10 ** 6);
        universalAdapter.sellBase(address(this), USDC_stS, abi.encode(0, abi.encode(USDC, stS)));
        console2.log("toToken balance after", IERC20(stS).balanceOf(address(this)));
    }
}

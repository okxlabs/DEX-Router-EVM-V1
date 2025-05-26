// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/Quickswapv3Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract QuickswapV3UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address payable WETH = payable(0x0Dc808adcE2099A9F62AA87D9670745AbA741746);
    address USDC = 0xb73603C5d87fA094B7314C74ACE2e64D165016fb;
    address WETH_USDC = 0x12CdDeD759B14bf6A34FbF6638aec9B735824a9E;

    Quickswapv3Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("MANTA_RPC_URL"), 5368306);
        customAdapter = new Quickswapv3Adapter(WETH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_quickswapV3_swapWETHtoUSDC_customAdapter() public {
        deal(WETH, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(this))); 
        IERC20(WETH).transfer(address(customAdapter), 1 * 10 ** 18);
        customAdapter.sellBase(address(this), WETH_USDC, abi.encode(0, abi.encode(WETH, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_quickswapV3_swapWETHtoUSDC_universalAdapter() public {
        deal(WETH, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(this))); 
        IERC20(WETH).transfer(address(universalAdapter), 1 * 10 ** 18);
        universalAdapter.sellBase(address(this), WETH_USDC, abi.encode(0, abi.encode(WETH, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

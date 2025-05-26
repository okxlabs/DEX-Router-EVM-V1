// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/NileCLAdapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract NileCLUniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x06f183D52D92c13a5f2B989B8710BA7F00bd6f87));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address payable WETH = payable(0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f); 
    address USDT = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;
    address WETH_USDT = 0x27ED78122B8eF363F4EF5B3aFe197e0c4A2Fa514;

    NileCLAdapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 19243351);
        customAdapter = new NileCLAdapter();
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_nileCL_swapWETHtoUSDT_universalAdapter() public user(bob) {
        deal(WETH, bob, 1 * 10 ** 16);
        IERC20(WETH).approve(tokenApprove, 1 * 10 ** 16);

        uint256 amount = IERC20(WETH).balanceOf(bob);
        SwapInfo memory swapInfo = genSwapInfo(address(universalAdapter), WETH, USDT, WETH_USDT, amount);

        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(bob)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(bob)));
    }
}

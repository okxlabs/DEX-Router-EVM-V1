// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/AgniFinanceAdapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract AgniFinanceUniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0xd30D8CA2E7715eE6804a287eB86FAfC0839b1380));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address payable WMNT = payable(0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8); 
    address USDT = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;
    address WMNT_USDT = 0xD08C50F7E69e9aeb2867DefF4A8053d9A855e26A;

    AgniFinanceAdapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("MANTLE_RPC_URL"), 79883371);
        customAdapter = new AgniFinanceAdapter(WMNT);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WMNT), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_agniFinance_swapWMNTtoUSDT_customAdapter() public user(bob) {
        deal(WMNT, bob, 1 * 10 ** 18);
        IERC20(WMNT).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(WMNT).balanceOf(bob);
        SwapInfo memory swapInfo = genSwapInfo(address(customAdapter), WMNT, USDT, WMNT_USDT, amount);

        console2.log("fromToken balance before", IERC20(WMNT).balanceOf(address(bob)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(bob)));
    }

    function test_agniFinance_swapWMNTtoUSDT_universalAdapter() public user(bob) {
        deal(WMNT, bob, 1 * 10 ** 18);
        IERC20(WMNT).approve(tokenApprove, 1 * 10 ** 18);

        uint256 amount = IERC20(WMNT).balanceOf(bob);
        SwapInfo memory swapInfo = genSwapInfo(address(universalAdapter), WMNT, USDT, WMNT_USDT, amount);

        console2.log("fromToken balance before", IERC20(WMNT).balanceOf(address(bob)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(bob)));
    }
}

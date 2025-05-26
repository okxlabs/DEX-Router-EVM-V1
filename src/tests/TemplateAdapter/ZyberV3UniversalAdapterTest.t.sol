// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/ZyberV3Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract ZyberV3UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x6088d94C5a40CEcd3ae2D4e0710cA687b91c61d0));
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;

    address payable WETH = payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address WETH_USDT = 0x227Ad861466853783f5956DdbB119235Ff4377b3;

    ZyberV3Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ARBI_RPC_URL"), 338809764);
        customAdapter = new ZyberV3Adapter(WETH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_camelotV3_swapWETHtoUSDC_customAdapter() public user(bob) {
        deal(WETH, bob, 1 * 10 ** 15);
        IERC20(WETH).approve(tokenApprove, 1 * 10 ** 15);

        uint256 amount = IERC20(WETH).balanceOf(bob);
        SwapInfo memory swapInfo = genSwapInfo(address(customAdapter), WETH, USDT, WETH_USDT, amount);

        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(bob)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(bob)));
    }

    function test_camelotV3_swapWETHtoUSDC_universalAdapter() public user(bob) {
        deal(WETH, bob, 1 * 10 ** 15);
        IERC20(WETH).approve(tokenApprove, 1 * 10 ** 15);

        uint256 amount = IERC20(WETH).balanceOf(bob);
        SwapInfo memory swapInfo = genSwapInfo(address(universalAdapter), WETH, USDT, WETH_USDT, amount);

        console2.log("fromToken balance before", IERC20(WETH).balanceOf(address(bob)));
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(bob)));
    }
}

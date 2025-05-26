// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/ThenaV2Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract ThenaV2UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;

    address payable WETH = payable(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address USDT = 0x55d398326f99059fF775485246999027B3197955;
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address USDC_USDT = 0x1b9a1120a17617D8eC4dC80B921A9A1C50Caef7d;

    address POOL_DEPLOYER = 0xc89F69Baa3ff17a842AB2DE89E5Fc8a8e2cc7358;
    bytes32 POOL_INIT_CODE_HASH = 0xd61302e7691f3169f5ebeca3a0a4ab8f7f998c01e55ec944e62cfb1109fd2736;

    ThenaV2Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 50110691);
        customAdapter = new ThenaV2Adapter(POOL_DEPLOYER, POOL_INIT_CODE_HASH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_thenaV2_swapUSDTtoUSDC_customAdapter() public {
        deal(USDT, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(USDT).balanceOf(address(this))); 
        IERC20(USDT).transfer(address(customAdapter), 1 * 10 ** 18);
        customAdapter.sellBase(address(this), USDC_USDT, abi.encode(0, abi.encode(USDT, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_quickswapV3_swapUSDTtoUSDC_universalAdapter() public {
        deal(USDT, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(USDT).balanceOf(address(this))); 
        IERC20(USDT).transfer(address(universalAdapter), 1 * 10 ** 18);
        universalAdapter.sellBase(address(this), USDC_USDT, abi.encode(0, abi.encode(USDT, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

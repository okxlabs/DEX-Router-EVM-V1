// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/FireFlyV3Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract FireFlyV3UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address payable WETH = payable (0x0Dc808adcE2099A9F62AA87D9670745AbA741746);
    address USDC = 0xb73603C5d87fA094B7314C74ACE2e64D165016fb; // decimals: 6
    address USDT = 0xf417F5A458eC102B90352F697D6e2Ac3A3d2851f; // decimals: 6
    
    address USDT_USDC = 0xb579a0028F6505D10206a58fCfB75f0B924Ed43F;

    FireFlyV3Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("MANTA_RPC_URL"), 5359374);
        customAdapter = new FireFlyV3Adapter(WETH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_fireFlyV3_swapUSDTtoUSDC_customAdapter() public {
        deal(USDT, address(this), 1 * 10 ** 6);
        console2.log("fromToken balance before", IERC20(USDT).balanceOf(address(this))); 
        IERC20(USDT).transfer(address(customAdapter), 1 * 10 ** 6);
        customAdapter.sellBase(address(this), USDT_USDC, abi.encode(0,abi.encode(USDT,USDC,100)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_fireFlyV3_swapUSDTtoUSDC_universalAdapter() public {
        deal(USDT, address(this), 1 * 10 ** 6);
        console2.log("fromToken balance before", IERC20(USDT).balanceOf(address(this))); 
        IERC20(USDT).transfer(address(universalAdapter), 1 * 10 ** 6);
        universalAdapter.sellBase(address(this), USDT_USDC, abi.encode(0,abi.encode(USDT,USDC,100)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

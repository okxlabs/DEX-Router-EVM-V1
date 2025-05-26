// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/KimV4Adapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract KimV4UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4));
    address tokenApprove = 0xbd0EBE49779E154E5042B34D5BcfBc498e4B3249;

    address payable WETH = payable(0x4200000000000000000000000000000000000006); 
    address USDC = 0xd988097fb8612cc24eeC14542bC03424c656005f;
    address KIM = 0x6863fb62Ed27A9DdF458105B507C15b5d741d62e;

    address KIM_USDC = 0xb3E3576aC813820021b1d1157Ec2285ab5C67D15;

    KimV4Adapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("MODE_RPC_URL"), 23868107);
        customAdapter = new KimV4Adapter(WETH);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WETH), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_kimv4_swapKIMtoUSDC_customAdapter() public {
        deal(KIM, address(this), 100 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(KIM).balanceOf(address(this))); 
        IERC20(KIM).transfer(address(customAdapter), 100 * 10 ** 18);
        customAdapter.sellBase(address(this), KIM_USDC, abi.encode(0, abi.encode(KIM, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }

    function test_kimv4_swapUSDCtoKIM_universalAdapter() public {
        deal(KIM, address(this), 100 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(USDC).balanceOf(address(this))); 
        IERC20(KIM).transfer(address(universalAdapter), 100 * 10 ** 18);
        universalAdapter.sellBase(address(this), KIM_USDC, abi.encode(0, abi.encode(KIM, USDC)));
        console2.log("toToken balance after", IERC20(USDC).balanceOf(address(this)));
    }
}

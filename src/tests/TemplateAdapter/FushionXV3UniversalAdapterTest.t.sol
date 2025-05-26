// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@dex/adapter/FushionXAdapter.sol";
import "@dex/adapter/TemplateAdaptor/UniversalUniswapV3Adaptor.sol";
import "./UniversalAdapterTestUtils.sol";

contract FushionXV3UniversalAdapterTest is UniversalAdapterTestUtils {
    DexRouter dexRouter = DexRouter(payable(0xd30D8CA2E7715eE6804a287eB86FAfC0839b1380));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;

    address factoryDeployer = 0x8790c2C3BA67223D83C8FCF2a5E3C650059987b4;
    address payable WMNT = payable(0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8); // decimals: 18
    address USDT = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;
    address WMNT_USDT = 0x262255F4770aEbE2D0C8b97a46287dCeCc2a0AfF;

    FushionXAdapter customAdapter;
    UniversalUniswapV3Adaptor universalAdapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("MANTLE_RPC_URL"), 79847381);
        customAdapter = new FushionXAdapter(WMNT, factoryDeployer);
        universalAdapter = new UniversalUniswapV3Adaptor(address(WMNT), MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    }

    function test_fushionXV3_swapWMNTtoUSDC_customAdapter() public {// user(bob) {
        deal(WMNT, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(WMNT).balanceOf(address(this))); 
        IERC20(WMNT).transfer(address(customAdapter), 1 * 10 ** 18);
        customAdapter.sellBase(address(this), WMNT_USDT, abi.encode(0,abi.encode(WMNT,USDT,500)));
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(this)));
    }

    function test_fushionXV3_swapWMNTtoUSDC_universalAdapter() public {// user(bob) {
        deal(WMNT, address(this), 1 * 10 ** 18);
        console2.log("fromToken balance before", IERC20(WMNT).balanceOf(address(this))); 
        IERC20(WMNT).transfer(address(universalAdapter), 1 * 10 ** 18);
        universalAdapter.sellBase(address(this), WMNT_USDT, abi.encode(0,abi.encode(WMNT,USDT,500)));
        console2.log("toToken balance after", IERC20(USDT).balanceOf(address(this)));
    }
}

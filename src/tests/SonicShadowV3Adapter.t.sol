pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";

/// @title SonicShadowV3Adapter
/// @notice do the usability test of former uniV3 adapter on Sonic for Shadow
/// @dev Explain to a developer any extra details
contract SonicShadowV3Adapter is Test {

    UniV3Adapter adapter;
    address WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address USDCToken0 = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;
    address WETHToken1 = 0x50c42dEAcD8Fc9773493ED674b675bE577f2634b;
    address USDCtoWETH = 0xCfD41dF89D060b72eBDd50d65f9021e4457C477e;

    function test_USDCtoWETH() public {
        vm.createSelectFork(vm.envString("SONIC_RPC_URL"), 10495673);
        adapter = new UniV3Adapter(payable(WS));
        deal(USDCToken0, address(this), 100 ether);

        console2.log(
            "USDC balance before",
            IERC20(USDCToken0).balanceOf(address(this))
        );
        console2.log(
            "WETH balance before",
            IERC20(WETHToken1).balanceOf(address(this))
        );

        IERC20(USDCToken0).transfer(address(adapter), 2360 * 10**6);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(USDCToken0, WETHToken1, uint24(3000));
        bytes memory moreInfo = abi.encode(sqrtX96, data);
        adapter.sellBase(address(this), USDCtoWETH, moreInfo);
        
        console2.log(
            "USDC balance after",
            IERC20(USDCToken0).balanceOf(address(this))
        );
        console2.log(
            "WETH balance after",
            IERC20(WETHToken1).balanceOf(address(this))
        );
    }
}
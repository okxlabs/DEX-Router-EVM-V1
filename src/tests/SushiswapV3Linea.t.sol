// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/UniV3Adapter.sol";

/// @title sushiV3LineaTest
/// @notice Do the usability test of sushiV3 adapter on Linea
/// @dev Explain to a developer any extra details

contract SushiV3LineaTest is Test {
    UniV3Adapter adapter;
    address WETH = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
    address axlUSDC = 0xEB466342C4d449BC9f53A865D5Cb90586f405215;
    
    address WETH_axlUSDC = 0xe5Ea78EBbacb76cD430E6832ee3E46EF15a82C56;
    //address WETH_axlUSDC = 0x6805f16924d163E515e49cb76cb19643797730A4;
    //address WETH_axlUSDC = 0xEBA4eD4CC80A2Fdc4F69E98245Ffc237e930A733;

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 483648);
        adapter = new UniV3Adapter(payable(WETH));
    }
 
    //WETH-axlUSDC 
    function test_1() public {
        deal(WETH, address(this), 1 ether);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WETH, axlUSDC, uint24(100));
        bytes memory moreInfo = abi.encode(sqrtX96, data);
        IERC20(WETH).transfer(address(adapter), 0.1 * 10**18);
        console2.log("alUSDC before:", IERC20(axlUSDC).balanceOf(address(this)));
        adapter.sellBase(address(this), WETH_axlUSDC , moreInfo);
        console2.log("alUSDC after", IERC20(axlUSDC).balanceOf(address(this)));
    }


}
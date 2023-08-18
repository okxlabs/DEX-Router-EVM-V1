// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/test.sol";

import "@dex/adapter/YearnAdapter.sol";

contract Addrs {
    address[] yTokens = [
        0xcd68c3fC3e94C5AcC10366556b836855D96bfa93,
        0xE2CaD35CFD1A9B5acD557558f44B096ef8340C1B,
        0x27B5739e22ad9033bcBf192059122d163b60349D,
        0x6E9455D109202b426169F0d8f01A3332DAE160f3,
        0xaA379c2aA72529d5ec0da8A41e2F41ED7Fe4b48C,
        0x8078198Fc424986ae89Ce4a910Fc109587b6aBF3,
        0xdA816459F1AB5631232FE5e97a05BBBb94970c95,
        0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE,
        0xa258C4606Ca8206D8aA700cE2143D7db854D168c,
        0x5B8C556B8b2a78696F0B9B830B3d67623122E270
    ];
}

contract YearnV1AdapterTest is Addrs, Test {
    YearnAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 17833988);
        adapter = new YearnAdapter();
    }
    // batch test v1

    function test_swap() public {
        for (uint256 i = 0; i < yTokens.length; i++) {
            address yToken = yTokens[i];
            address underlying = yVault(yToken).token();
            uint256 decimals = yVault(yToken).decimals();
            uint256 price = yVault(yToken).pricePerShare();
            deal(underlying, address(this), 10 ** decimals);
            SafeERC20.safeTransfer(IERC20(underlying), address(adapter), 10 ** decimals);
            adapter.sellBase(address(this), yToken, abi.encode(underlying, yToken));
            uint256 amountRes = IERC20(yToken).balanceOf(address(this));
            uint256 amountExp = 10 ** decimals * 10 ** decimals / price;
            assertApproxEqAbs(amountRes, amountExp, 2);
            price = yVault(yToken).pricePerShare();
            IERC20(yToken).transfer(address(adapter), amountRes);
            adapter.sellQuote(address(this), yToken, abi.encode(yToken, underlying));
            amountExp = amountRes * price / 10 ** decimals;
            amountRes = IERC20(underlying).balanceOf(address(this));
            assertApproxEqAbs(amountRes, amountExp, 2);
        }
    }

    // batch test v2
}

pragma solidity ^0.8.0;

import {DyorPumpRouterV3Adapter} from "contracts/8/adapter/DyorPumpRouterV3Adapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";

contract DyorPumpRouterV3AdapterSpecialTest is Test {
    // https://www.oklink.com/zh-hans/x-layer/tx/0x830ed4300720f80b9130770fdcd69c9fe13943448d7c05417f3fb8a026651b41
    function test_sellQuote() public {
        vm.createSelectFork(
            "xlayer", 
            35904465 - 1
        );
        address WETH = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
        address dyorPumpRouterV3 = 0xD983C98D1522731146bAd34078dA0bD966D9EA08;

        DyorPumpRouterV3Adapter adapter = new DyorPumpRouterV3Adapter(dyorPumpRouterV3, WETH);

        address okb = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address pandas = 0xeBbF2f1C007a1e6EAE88372B1061DD0E1015B8d0;
        // address pandas_wokb_pool = pandas; // unused in this test
        address user = address(0xEB33b04b8731966DA91990C681f880F379050f33);
        uint256 amount = 10000 * 10 ** 18;
        bytes memory moreInfo = abi.encode(
            pandas,  // fundAddress
            okb, // tokenAddress
            false, // buyMeme
            amount, // sellMemeAmount
            0, // sellCommissionRate1
            address(0), // sellCommissionReceiver1
            0, // sellCommissionRate2
            address(0), // sellCommissionReceiver2
            0 // minReturnAmount
        );

        // Give user enough tokens for testing
        deal(pandas, user, amount);
        
        // Check balance before
        uint256 balanceBefore = IERC20(pandas).balanceOf(user);
        require(balanceBefore >= amount, "Insufficient balance");

        vm.startPrank(user, user);  // Set both msg.sender and tx.origin to user
        vm.txGasPrice(1);  // Set a consistent gas price
            // Since DyorPumpRouterV3 transfers from tx.origin, user needs to:
            // 1. Have the tokens in their account (done with deal above)
            // 2. Approve the router to spend tokens
            IERC20(pandas).approve(dyorPumpRouterV3, amount);
            
            // Call adapter - router will transfer from user (tx.origin)
            adapter.sellQuote(
                user, // recipient for ETH output
                pandas, // pool/token address
                moreInfo
            );
        vm.stopPrank();
    }
}
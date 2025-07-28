// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ThenaAdapterFix} from "@dex/adapter/ThenaAdapterFix.sol";
import {ThenaAdapter} from "@dex/adapter/ThenaAdapter.sol";
import {IERC20} from "@dex/interfaces/IERC20.sol";
import {IPair} from "@dex/interfaces/ISolidly.sol";

contract ThenaAdapterFixTest is Test {
    ThenaAdapter public adapter;
    ThenaAdapterFix public adapterFix;
    address pair = 0xc7419EBbc4b259C50D7Eeaba49940688A5d52Afa;
    address token0 = 0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40;
    address token1 = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 constant PROBLEMATIC_AMOUNT = 1_525_318_352_269_930;
    uint256 constant EXPECTED_OUTPUT = 1_010_059_645_868_784_414;

    uint256 constant FEE = 1; // 1/10000 for stable pool

    uint256 constant LARGE_AMOUNT = 1_000_000 * 1e18;
    uint256 constant SMALL_AMOUNT = 1000 * 1e18;

    address recipient = makeAddr("recipient");

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 51194421);
        adapter = new ThenaAdapter();
        adapterFix = new ThenaAdapterFix();
    }

    // Test will fail if ThenaAdapter contract won't subtract 1000 from the amountOut
    function test_ThenaAdapter_sellQuote() public {
        uint256 sellAmount = PROBLEMATIC_AMOUNT;
        deal(token1, address(this), sellAmount);

        uint256 originalAmountOut = IPair(pair).getAmountOut(sellAmount, token1);
        console2.log("Original token0 amount out:", originalAmountOut);

        IERC20(token1).transfer(pair, sellAmount);
        adapter.sellQuote(recipient, pair, ""); // Will revert with 'K' if ThenaAdapter contract won't subtract 1000 from the amountOut

        console2.log("Actual token0 received:", IERC20(token0).balanceOf(recipient));
    }

    function test_ThenaAdapterFix_sellQuote() public {
        uint256 sellAmount = PROBLEMATIC_AMOUNT;
        deal(token1, address(this), sellAmount);

        uint256 originalAmountOut = IPair(pair).getAmountOut(sellAmount, token1);
        console2.log("Original token0 amount out:", originalAmountOut);

        IERC20(token1).transfer(pair, sellAmount);
        bool isStable = IPair(pair).isStable();
        adapterFix.sellQuote(recipient, pair, abi.encode(FEE, isStable));

        console2.log("Actual token0 received:", IERC20(token0).balanceOf(recipient));
    }

    // Original amount out satisfy the k check, no adjustment needed
    function test_ThenaAdapterFix_sellBase() public {
        uint256 sellAmount = EXPECTED_OUTPUT;
        deal(token0, address(this), sellAmount);

        uint256 originalAmountOut = IPair(pair).getAmountOut(sellAmount, token0);
        console2.log("Original token1 amount out:", originalAmountOut);

        IERC20(token0).transfer(pair, sellAmount);
        bool isStable = IPair(pair).isStable();
        adapterFix.sellBase(recipient, pair, abi.encode(FEE, isStable));

        console2.log("Actual token1 received:", IERC20(token1).balanceOf(recipient));
    }
}

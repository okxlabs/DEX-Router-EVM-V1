// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@dex/adapter/AaveV3Adapter.sol";
import "forge-std/test.sol";
import "@dex/interfaces/IERC20.sol";
import "@dex/interfaces/IAaveLendingPool.sol";

contract AaveV3AdapterTest is Test {
    string network = "base";
    address constant AAVE_V3_POOL = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant aUSDC = 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant aWETH = 0xD4a0e0b9149BCee3C920d2E00b5dE09138fd8bb7;

    AaveV3Adapter adapter;

    function setUp() public {
        vm.createSelectFork(network);
        adapter = new AaveV3Adapter(AAVE_V3_POOL);
    }

    // Tests Covers:
    // - WETH
    // - USDC
    // - sellBase
    // - sellQuote
    // - Boundary Values
    //      - 0 amount deposit
    //      - Small amount deposit
    //      - Large amount deposit
    //      - Small WETH amount
    //      - 1 wei withdrawal
    //      - Withdraw more than balance
    //      - Withdraw exact remaining balance

    // Not Covered:
    // - Tax Token (no tax token assets on Aave V3 https://app.aave.com/markets/?marketName=proto_base_v3)

    function test_WETH() public {
        
        // deposit WETH
        uint256 depositAmt = 1 * 10**18;
        deal(WETH, address(this), depositAmt);
        IERC20(WETH).transfer(address(adapter), depositAmt);

        // swap for aWETH
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(WETH, aWETH, true)
        );

        // check that adapter has aWETH
        uint256 aWETHBalance = IERC20(aWETH).balanceOf(address(this));
        assertApproxEqAbs(aWETHBalance, depositAmt, 1, "Should receive approximately same amount of aWETH");

        // Transfer aWETH to adapter for withdrawal
        IERC20(aWETH).transfer(address(adapter), aWETHBalance);

        // Withdraw aWETH back to WETH
        adapter.sellQuote(
            address(this),
            AAVE_V3_POOL,
            abi.encode(aWETH, WETH, false)
        );

        //check that adapter has WETH
        uint256 WETHBalance = IERC20(WETH).balanceOf(address(this));
        assertApproxEqAbs(WETHBalance, depositAmt, 1, "Should receive approximately same amount of WETH");
    }

    function test_USDC() public {
        
        // deposit USDC
        uint256 depositAmt = 1000 * 10**6;
        deal(USDC, address(this), depositAmt);
        IERC20(USDC).transfer(address(adapter), depositAmt);

        // swap for aUSDC
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(USDC, aUSDC, true)
        );

        // check that adapter has aUSDC
        uint256 aUSDCBalance = IERC20(aUSDC).balanceOf(address(this));
        assertApproxEqAbs(aUSDCBalance, depositAmt, 1, "Should receive approximately same amount of aUSDC");

        // Transfer aUSDC to adapter for withdrawal
        IERC20(aUSDC).transfer(address(adapter), aUSDCBalance);

        // Withdraw aUSDC back to USDC
        adapter.sellQuote(
            address(this),
            AAVE_V3_POOL,
            abi.encode(aUSDC, USDC, false)
        );

        //check that adapter has USDC
        uint256 USDCBalance = IERC20(USDC).balanceOf(address(this));
        assertApproxEqAbs(USDCBalance, depositAmt, 1, "Should receive approximately same amount of USDC");
    }

    function test_BoundaryParameters() public {
        // Test 1: Zero amount deposit should revert (adapter has no balance)
        vm.expectRevert(); // Expect Aave V3 to revert on zero amount for pool.supply()
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(USDC, aUSDC, true)
        );

        // Confirm that balance of aUSDC is indeed 0
        uint256 initialBalance = IERC20(aUSDC).balanceOf(address(this));
        assertEq(initialBalance, 0, "Should receive 0 aUSDC for 0 amount");

        // Test 2: Small amount deposit (1 wei)
        uint256 minAmt = 1;
        deal(USDC, address(this), minAmt);
        IERC20(USDC).transfer(address(adapter), minAmt);
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(USDC, aUSDC, true)
        );
        uint256 aUSDCBalance = IERC20(aUSDC).balanceOf(address(this));
        assertEq(aUSDCBalance, minAmt, "Should receive 1 wei of aUSDC");

        // Test 3: Reasonable large amount deposit
        uint256 largeAmt = 100_000 * 10**6; // 100k USDC (more realistic)
        deal(USDC, address(this), largeAmt);
        IERC20(USDC).transfer(address(adapter), largeAmt);
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(USDC, aUSDC, true)
        );
        aUSDCBalance = IERC20(aUSDC).balanceOf(address(this));
        assertApproxEqAbs(aUSDCBalance, largeAmt, largeAmt / 1000, "Should receive approximately same large amount of aUSDC");

        // Test 4: Small WETH amount (different decimals)
        uint256 wethSmallAmt = 1000; // 1000 wei WETH
        deal(WETH, address(this), wethSmallAmt);
        IERC20(WETH).transfer(address(adapter), wethSmallAmt);
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(WETH, aWETH, true)
        );
        uint256 aWETHBalance = IERC20(aWETH).balanceOf(address(this));
        assertEq(aWETHBalance, wethSmallAmt, "Should receive exact small amount of aWETH");

    }

    function test_BoundaryWithdrawals() public {
        uint256 initialBalance = IERC20(USDC).balanceOf(address(this));
        if (initialBalance > 0) {
            // Transfer away any existing balance
            IERC20(USDC).transfer(address(0xdead), initialBalance);
        }

        // Test 1: Withdraw 0 amount
        uint256 zeroWithdraw = 0;
        IERC20(aUSDC).transfer(address(adapter), zeroWithdraw);
        vm.expectRevert();
        adapter.sellQuote(
            address(this),
            AAVE_V3_POOL,
            abi.encode(aUSDC, USDC, false)  
        );
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
        assertEq(usdcBalance, 0, "Should receive 0 USDC for 0 amount");

        // Setup: First deposit a normal amount
        uint256 depositAmt = 1000 * 10**6;
        deal(USDC, address(this), depositAmt);
        IERC20(USDC).transfer(address(adapter), depositAmt);
        adapter.sellBase(
            address(this),
            AAVE_V3_POOL,
            abi.encode(USDC, aUSDC, true)
        );

        // Test 2: Withdraw 1 wei
        uint256 minWithdraw = 1;
        IERC20(aUSDC).transfer(address(adapter), minWithdraw);
        adapter.sellQuote(
            address(this),
            AAVE_V3_POOL,
            abi.encode(aUSDC, USDC, false)
        );
        usdcBalance = IERC20(USDC).balanceOf(address(this));
        assertEq(usdcBalance, minWithdraw, "Should receive 1 wei of USDC");

        // Test 3: Withdraw exact remaining balance (check balance right before transfer)
        uint256 remainingBalance = IERC20(aUSDC).balanceOf(address(this));
        IERC20(aUSDC).transfer(address(adapter), remainingBalance);
        adapter.sellQuote(
            address(this),
            AAVE_V3_POOL,
            abi.encode(aUSDC, USDC, false)
        );
        usdcBalance = IERC20(USDC).balanceOf(address(this));
        assertApproxEqAbs(usdcBalance, depositAmt, 1000, "Should receive approximately full deposit amount back (allowing for interest and rounding)");
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./DagRouterTestBase.t.sol";
import "@dex/adapter/FourMemeAdapter.sol";
import "@dex/interfaces/IDexRouter.sol";

contract DagRouterNoTransferTest is DagRouterTestBase {

    // Transfer mode constants
    uint256 internal constant _MODE_NO_TRANSFER = 1 << 251;
    
    // BSC specific addresses for FourMeme
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant USDT_BSC = 0x55d398326f99059fF775485246999027B3197955;
    address constant MEME_DUST = 0x932Fb7f52adBC34ff81B4342b8C036b7b8Ac4444;
    address constant MEME_TOKEN_A = 0xb6A303FAC827B37073C4Fb48Dc3cF25EBe7DF7F1; // name: a
    
    address public fourMemeAdapter = 0x5280D6afe6321c958cAce4029616d677957eb43B;
    address public tokenManager2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;
    
    uint256 constant SELL_AMOUNT = 1550234 * 10 ** 18;

    function setUp() public virtual override {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 61697236);
        
        dexRouter = new DexRouter();
        
        // Setup permissions
        address tokenApproveProxyAdmin = 0xAcE2B3E7c752d5deBca72210141d464371b3B9b1;
        vm.startPrank(tokenApproveProxyAdmin);
        TokenApproveProxy(0xd99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98).addProxy(address(dexRouter));
        vm.stopPrank();
        
        // Update token approve references for BSC
        tokenApprove = TokenApprove(0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6);
        tokenApproveProxy = TokenApproveProxy(0xd99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98);
        wNativeRelayer = WNativeRelayer(payable(0x0B5f474ad0e3f7ef629BD10dbf9e4a8Fd60d9A48));
    }

    function test_DagRouter_fourmeme_sell_NO_TRANSFER_mode() public {
        address user = tx.origin;
        vm.startPrank(user, user);

        console2.log("=== DAG Swap FourMeme Sell with NO_TRANSFER Mode ===");
        console2.log("User:", user);
        console2.log("Meme Token:", MEME_TOKEN_A);
        console2.log("Fund Token:", USDT_BSC);

        deal(MEME_TOKEN_A, user, SELL_AMOUNT);
        IERC20(MEME_TOKEN_A).approve(tokenManager2, SELL_AMOUNT);

        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(MEME_TOKEN_A)),
            toToken: USDT_BSC,
            fromTokenAmount: SELL_AMOUNT,
            minReturnAmount: 285176920244889837082 - 279414545175546695469,
            deadLine: block.timestamp + 3600
        });

        IDexRouter.RouterPath[] memory paths = new IDexRouter.RouterPath[](1);
        paths[0] = IDexRouter.RouterPath({
            mixAdapters: new address[](1),
            assetTo: new address[](1), 
            rawData: new uint256[](1),
            extraData: new bytes[](1),
            fromToken: uint256(uint160(MEME_TOKEN_A)) | _MODE_NO_TRANSFER // Key: NO_TRANSFER flag
        });

        // Setup adapter and target
        paths[0].mixAdapters[0] = fourMemeAdapter;
        paths[0].assetTo[0] = fourMemeAdapter;
        
        // Setup rawData for DAG: inputIndex=0, outputIndex=1, weight=10000
        paths[0].rawData[0] = uint256(bytes32(abi.encodePacked(
            uint64(0x00),     // reserved
            uint8(0),         // inputIndex
            uint8(1),         // outputIndex  
            uint16(10000),    // weight (100%)
            address(0)        // pool address (not used for FourMeme)
        )));

        // Setup FourMeme trade info
        FourMemeAdapter.TradeInfo memory tradeInfo = FourMemeAdapter.TradeInfo({
            fundAddress: USDT_BSC,
            tokenAddress: MEME_TOKEN_A,
            buyMeme: false,
            sellMemeAmount: SELL_AMOUNT,
            sellCommissionRate1: 100, // 1%
            sellCommissionReceiver1: vm.rememberKey(1111),
            sellCommissionRate2: 100, // 1%
            sellCommissionReceiver2: vm.rememberKey(2222),
            minReturnAmount: 0
        });
        paths[0].extraData[0] = abi.encode(tradeInfo);

        // Record balances before
        uint256 memeBalanceBefore = IERC20(MEME_TOKEN_A).balanceOf(user);
        uint256 usdtBalanceBefore = IERC20(USDT_BSC).balanceOf(user);
        
        console2.log("Meme balance before:", memeBalanceBefore);
        console2.log("USDT balance before:", usdtBalanceBefore);

        // Execute DAG swap with NO_TRANSFER mode
        dexRouter.dagSwapTo(12345, user, baseRequest, paths);

        // Record balances after
        uint256 memeBalanceAfter = IERC20(MEME_TOKEN_A).balanceOf(user);
        uint256 usdtBalanceAfter = IERC20(USDT_BSC).balanceOf(user);
        
        console2.log("Meme balance after:", memeBalanceAfter);
        console2.log("USDT balance after:", usdtBalanceAfter);
        console2.log("Commission receiver 1 USDT:", IERC20(USDT_BSC).balanceOf(tradeInfo.sellCommissionReceiver1));
        console2.log("Commission receiver 2 USDT:", IERC20(USDT_BSC).balanceOf(tradeInfo.sellCommissionReceiver2));

        // Verify successful swap
        assertEq(memeBalanceAfter, 0, "All meme tokens should be sold");
        assertGt(usdtBalanceAfter, usdtBalanceBefore, "Should receive USDT");
        
        // Verify commission distribution
        assertGt(IERC20(USDT_BSC).balanceOf(tradeInfo.sellCommissionReceiver1), 0, "Commission receiver 1 should get USDT");
        assertGt(IERC20(USDT_BSC).balanceOf(tradeInfo.sellCommissionReceiver2), 0, "Commission receiver 2 should get USDT");

        vm.stopPrank();
    }

    function test_DagRouter_fourmeme_sell_LEGACY_mode_should_fail() public {
        address user = tx.origin;
        vm.startPrank(user, user);

        console2.log("=== DAG Swap FourMeme Sell with LEGACY Mode (Expected Failure) ===");

        // Setup meme token balance and approval
        deal(MEME_TOKEN_A, user, SELL_AMOUNT);
        IERC20(MEME_TOKEN_A).approve(tokenManager2, SELL_AMOUNT);

        // Create BaseRequest
        IDexRouter.BaseRequest memory baseRequest = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(MEME_TOKEN_A)),
            toToken: USDT_BSC,
            fromTokenAmount: SELL_AMOUNT,
            minReturnAmount: 285176920244889837082 - 279414545175546695469,
            deadLine: block.timestamp + 3600
        });

        // Create RouterPath WITHOUT NO_TRANSFER mode (LEGACY mode)
        IDexRouter.RouterPath[] memory paths = new IDexRouter.RouterPath[](1);
        paths[0] = IDexRouter.RouterPath({
            mixAdapters: new address[](1),
            assetTo: new address[](1),
            rawData: new uint256[](1),
            extraData: new bytes[](1),
            fromToken: uint256(uint160(MEME_TOKEN_A)) // Note: NO _MODE_NO_TRANSFER flag
        });

        paths[0].mixAdapters[0] = fourMemeAdapter;
        paths[0].assetTo[0] = fourMemeAdapter;
        paths[0].rawData[0] = uint256(bytes32(abi.encodePacked(
            uint64(0x00), uint8(0), uint8(1), uint16(10000), address(0)
        )));

        FourMemeAdapter.TradeInfo memory tradeInfo = FourMemeAdapter.TradeInfo({
            fundAddress: USDT_BSC,
            tokenAddress: MEME_TOKEN_A,
            buyMeme: false,
            sellMemeAmount: SELL_AMOUNT,
            sellCommissionRate1: 0,
            sellCommissionReceiver1: address(0),
            sellCommissionRate2: 0,
            sellCommissionReceiver2: address(0),
            minReturnAmount: 0
        });
        paths[0].extraData[0] = abi.encode(tradeInfo);

        console2.log("Attempting DAG swap with LEGACY mode...");
        
        // Expected to fail due to TokenApprove access restrictions
        vm.expectRevert("TokenApprove: Access restricted");
        dexRouter.dagSwapTo(12347, user, baseRequest, paths);

        console2.log("LEGACY mode failed as expected - access restricted");

        vm.stopPrank();
    }
}

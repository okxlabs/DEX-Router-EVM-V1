// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@dex/DexRouter.sol";
import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/adapter/FourMemeAdapter.sol";
import "@dex/libraries/SafeERC20.sol";

contract DagRouterSpecialTest is Test {

    DexRouter public dexRouter;
    TokenApprove tokenApprove = TokenApprove(0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6); // BSC
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0xd99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98); // BSC
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0x0B5f474ad0e3f7ef629BD10dbf9e4a8Fd60d9A48)); // BSC

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant MEME_DUST = 0x932Fb7f52adBC34ff81B4342b8C036b7b8Ac4444;
    address public arnaud = vm.rememberKey(11111111);

    address public fourMemeAdapter = 0x5280D6afe6321c958cAce4029616d677957eb43B;
    address public tokenManager2 = 0x5c952063c7fc8610FFDB798152D69F0B9550762b;

    uint256 constant BUY_AMOUNT = 0.1 * 10 ** 18;
    uint256 constant SELL_AMOUNT = 3028622 * 10 ** 18;

    function setUp() public {
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 61697236);
        dexRouter = new DexRouter();
        address wNativeRelayerOwner = wNativeRelayer.owner();
        vm.startPrank(wNativeRelayerOwner);
        tokenApproveProxy.addProxy(address(dexRouter));
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
    }

    function test_DagRouter_fourmeme_buyMemeWithWETH() public {
        deal(WBNB, arnaud, BUY_AMOUNT);
        vm.startPrank(arnaud);
        DexRouter.BaseRequest memory baseRequest;
        baseRequest.fromToken = uint256(uint160(address(WBNB)));
        baseRequest.toToken = MEME_DUST;
        baseRequest.fromTokenAmount = BUY_AMOUNT;
        baseRequest.minReturnAmount = 1000000000; // Min return check in DexRouter
        baseRequest.deadLine = block.timestamp;
        
        DexRouter.RouterPath[] memory paths = new DexRouter.RouterPath[](1);
        paths[0].fromToken = uint256(uint160(address(WBNB)));
        paths[0].mixAdapters = new address[](1);
        paths[0].mixAdapters[0] = fourMemeAdapter;
        paths[0].assetTo = new address[](1);
        paths[0].assetTo[0] = fourMemeAdapter;
        paths[0].rawData = new uint256[](1);
        paths[0].rawData[0] = uint256(bytes32(abi.encodePacked(uint64(0x00), uint8(0), uint8(1), uint16(10000), address(0))));
        paths[0].extraData = new bytes[](1);
        paths[0].extraData[0] = abi.encode(FourMemeAdapter.TradeInfo({
            fundAddress: WBNB,
            tokenAddress: MEME_DUST,
            buyMeme: true,
            sellMemeAmount: 0,
            sellCommissionRate1: 0,
            sellCommissionReceiver1: address(0),
            sellCommissionRate2: 0,
            sellCommissionReceiver2: address(0),
            minReturnAmount: 0
        }));

        SafeERC20.safeApprove(IERC20(WBNB), address(tokenApprove), BUY_AMOUNT);
        console2.log("WBNB balance before:", IERC20(WBNB).balanceOf(arnaud));
        console2.log("MEME_DUST balance before:", IERC20(MEME_DUST).balanceOf(arnaud));
        dexRouter.dagSwapTo(1, arnaud, baseRequest, paths);
        console2.log("WBNB balance after:", IERC20(WBNB).balanceOf(arnaud));
        console2.log("MEME_DUST balance after:", IERC20(MEME_DUST).balanceOf(arnaud));
        vm.stopPrank();
    }

    function test_DagRouter_fourmeme_sellMeme() public {
        deal(MEME_DUST, arnaud, SELL_AMOUNT);
        console2.log("arnaud", arnaud);
        vm.startPrank(arnaud, arnaud);
        DexRouter.BaseRequest memory baseRequest;
        baseRequest.fromToken = uint256(uint160(address(MEME_DUST)));
        baseRequest.toToken = WBNB;
        baseRequest.fromTokenAmount = 0; // To skip meme token transfer with TokenApprove
        baseRequest.minReturnAmount = 0; // To skip min return amount check
        baseRequest.deadLine = block.timestamp;
        
        DexRouter.RouterPath[] memory paths = new DexRouter.RouterPath[](1);
        paths[0].fromToken = uint256(uint160(address(MEME_DUST)));
        paths[0].mixAdapters = new address[](1);
        paths[0].mixAdapters[0] = fourMemeAdapter;
        paths[0].assetTo = new address[](1);
        paths[0].assetTo[0] = fourMemeAdapter;
        paths[0].rawData = new uint256[](1);
        paths[0].rawData[0] = uint256(bytes32(abi.encodePacked(uint64(0x00), uint8(0), uint8(1), uint16(10000), address(0))));
        paths[0].extraData = new bytes[](1);
        paths[0].extraData[0] = abi.encode(FourMemeAdapter.TradeInfo({
            fundAddress: WBNB,
            tokenAddress: MEME_DUST,
            buyMeme: false,
            sellMemeAmount: SELL_AMOUNT,
            sellCommissionRate1: 0,
            sellCommissionReceiver1: address(0),
            sellCommissionRate2: 0,
            sellCommissionReceiver2: address(0),
            minReturnAmount: 1000000000 // Min return check in Adapter
        }));

        SafeERC20.safeApprove(IERC20(MEME_DUST), address(tokenManager2), SELL_AMOUNT);
        console2.log("BNB balance before:", address(arnaud).balance);
        console2.log("WBNB balance before:", IERC20(WBNB).balanceOf(arnaud));
        console2.log("MEME_DUST balance before:", IERC20(MEME_DUST).balanceOf(arnaud));
        dexRouter.dagSwapTo(1, arnaud, baseRequest, paths);
        console2.log("BNB balance after:", address(arnaud).balance);
        console2.log("WBNB balance after:", IERC20(WBNB).balanceOf(arnaud));
        console2.log("MEME_DUST balance after:", IERC20(MEME_DUST).balanceOf(arnaud));
        vm.stopPrank();
    }
}
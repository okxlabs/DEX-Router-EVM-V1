pragma solidity 0.8.12;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/OKXLimitOrderAdapter.sol";

contract OKXLimitOrderAdapterTest is Test {
    OKXLimitOrderAdapter adapter;
    address OKXLimitOrderV2 = 0x88D6067D21Bb69198E081FE7FF270E94975065C7;
    address tokenApprove = 0x3B86917369B83a6892f553609F3c2F439C184e31;
    address wNativeToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address USDCe = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address FTM = 0xC9c1c1c20B3658F8787CC2FD702267791f224Ce1;

    address maker = vm.rememberKey(vm.envUint("PRIVATE_KEY_MAKER"));
    address taker = vm.rememberKey(vm.envUint("PRIVATE_KEY_TAKER"));

    function setUp() public {
        vm.createSelectFork(vm.envString("POLYGON_RPC_URL"), 48586347);

        console2.log("##### maker:", maker);
        console2.log("##### taker:", taker);
        console2.log("block.chainID", block.chainid);
        require(block.chainid == 137, "must be polygon chainId");

        //new adapter
        // adapter = new OKXLimitOrderAdapter(
        //     OKXLimitOrderV2,
        //     tokenApprove,
        //     wNativeToken
        // );

        //onchain adapter
        adapter = OKXLimitOrderAdapter(
            payable(0x26cD030a7307E168eC9ccC30137629A5Ed8BaCD2)
        );
    }

    function test_fillOrder_byERC20() public {
        uint256 makingAmount = 2 * 1e6;
        uint256 takingAmount = 10 * 1e18;
        //uint256 actualMakingAmount = 1 * 1e6;
        uint256 actualTakingAmount = 5 * 1e18;
        deal(USDCe, maker, makingAmount);
        deal(FTM, taker, actualTakingAmount);

        Order memory order = Order({
            salt: 0x01,
            makerToken: USDCe,
            takerToken: FTM,
            maker: address(maker),
            receiver: address(maker),
            allowedSender: address(0),
            makingAmount: makingAmount,
            takingAmount: takingAmount,
            minReturn: takingAmount,
            deadLine: 1777747155,
            partiallyAble: true
        });

        uint256 beforeMakerUSDCe = IERC20(USDCe).balanceOf(maker);
        uint256 beforeMakerFTM = IERC20(FTM).balanceOf(maker);
        uint256 beforeTakerUSDCe = IERC20(USDCe).balanceOf(taker);
        uint256 beforeTakerFTM = IERC20(FTM).balanceOf(taker);

        vm.prank(maker);
        IERC20(USDCe).approve(address(tokenApprove), makingAmount);

        vm.startPrank(taker);
        IERC20(FTM).transfer(address(adapter), actualTakingAmount);
        adapter.sellBase(
            address(taker),
            address(0),
            abi.encode(order, signOrder(order))
        );
        vm.stopPrank();

        uint256 afterMakerUSDCe = IERC20(USDCe).balanceOf(maker);
        uint256 afterMakerFTM = IERC20(FTM).balanceOf(maker);
        uint256 afterTakerUSDCe = IERC20(USDCe).balanceOf(taker);
        uint256 afterTakerFTM = IERC20(FTM).balanceOf(taker);

        console2.log(
            "change maker USDCe",
            int(afterMakerUSDCe) - int(beforeMakerUSDCe)
        );
        console2.log(
            "change maker FTM",
            int(afterMakerFTM) - int(beforeMakerFTM)
        );
        console2.log(
            "change taker USDCe",
            int(afterTakerUSDCe) - int(beforeTakerUSDCe)
        );
        console2.log(
            "change taker FTM",
            int(afterTakerFTM) - int(beforeTakerFTM)
        );
    }

    function test_fillOrder_byETH() public {
        uint256 makingAmount = 1600 * 1e6;
        uint256 takingAmount = 1 * 1e18;
        //uint256 actualMakingAmount = 800 * 1e6;
        uint256 actualTakingAmount = 0.5 * 1e18;

        deal(USDCe, maker, makingAmount);
        deal(wNativeToken, taker, 1.5 ether);

        Order memory order = Order({
            salt: 0x02,
            makerToken: USDCe,
            takerToken: ETH,
            maker: address(maker),
            receiver: address(maker),
            allowedSender: address(0),
            makingAmount: makingAmount,
            takingAmount: takingAmount,
            minReturn: takingAmount,
            deadLine: 1777747155,
            partiallyAble: true
        });

        uint256 beforeMakerUSDCe = IERC20(USDCe).balanceOf(maker);
        uint256 beforeMakerETH = maker.balance;
        uint256 beforeTakerUSDCe = IERC20(USDCe).balanceOf(taker);
        uint256 beforeTakerWETH = IERC20(wNativeToken).balanceOf(taker);

        vm.prank(maker);
        IERC20(USDCe).approve(address(tokenApprove), makingAmount);

        vm.startPrank(taker);
        IERC20(wNativeToken).transfer(address(adapter), actualTakingAmount);
        adapter.sellBase(
            address(taker),
            address(0),
            abi.encode(order, signOrder(order))
        );
        vm.stopPrank();

        uint256 afterMakerUSDCe = IERC20(USDCe).balanceOf(maker);
        uint256 afterMakerETH = maker.balance;
        uint256 afterTakerUSDCe = IERC20(USDCe).balanceOf(taker);
        uint256 afterTakerWETH = IERC20(wNativeToken).balanceOf(taker);

        console2.log(
            "change maker USDCe",
            int(afterMakerUSDCe) - int(beforeMakerUSDCe)
        );
        console2.log(
            "change maker ETH",
            int(afterMakerETH) - int(beforeMakerETH)
        );
        console2.log(
            "change taker USDCe",
            int(afterTakerUSDCe) - int(beforeTakerUSDCe)
        );
        console2.log(
            "change taker WETH",
            int(afterTakerWETH) - int(beforeTakerWETH)
        );
    }

    function signOrder(
        Order memory order
    ) internal view returns (bytes memory signature) {
        bytes32 digest = IOKXLimitOrder(OKXLimitOrderV2).hashOrder(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("PRIVATE_KEY_MAKER"),
            digest
        );
        signature = abi.encodePacked(r, s, v);
    }
}

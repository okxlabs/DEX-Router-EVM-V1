// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/BabyDogeAdapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract BabyDogeAdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0x9333C74BDd1E118634fE5664ACA7a9710b108Bab));
    address tokenApprove = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
    address router = 0xC9a0F685F39d05D835c369036251ee3aEaaF3c47;

    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address BUSD = 0x55d398326f99059fF775485246999027B3197955;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address GVC = 0xe1443170faB91fBA2c535b3f78935d6fcE55348d;
    address BabyDoge = 0xc748673057861a797275CD8A068AbB95A902e8de;
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address USDC_BUSD = 0x30949Ff5752f82d7aE6d0b0FCecF9f785ac8d95A;
    address GVC_WETH = 0x8068876Be0977c9ceE0d3a73a978198F72a39a87;
    address BabyDoge_WETH = 0x0536c8b0c3685b6e3C62A7b5c4E8b83f938f12D1;
    
    address bob = vm.rememberKey(1);
    address userA = 0x28D940A148ed9b80b0F72f6Ac8d9F7313cC1eea0;

    BabyDogeAdapter adapter;

    function setUp() public {
        //https://bscscan.com/tx/0x1dd229b0583ef45dfc71d2eacb220e3a45e649d8639aa5e29ff820fc38bd9f64
        // vm.createSelectFork(vm.envString("BSC_RPC_URL"), 38243981-1);

        //https://bscscan.com/tx/0xc5514354cbb4d66a02f6987500b1bb3fdfb6806a121580ce213cf4c04952c6ed
        // vm.createSelectFork(vm.envString("BSC_RPC_URL"), 38268658-1);

        //https://bscscan.com/tx/0x564b178d0743f8da413eb33881630622637ba9a10368b581938003f476343567
        vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        adapter = new BabyDogeAdapter(payable(router));
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
        console2.log("BUSD balance before", IERC20(BUSD).balanceOf(address(_user)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        console2.log("GVC balance before", IERC20(GVC).balanceOf(address(_user)));
        console2.log("ETH balance before", address(_user).balance);
        console2.log("BabyDoge balance before", IERC20(BabyDoge).balanceOf(address(_user)));
        _;
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
        console2.log("BUSD balance after", IERC20(BUSD).balanceOf(address(_user)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(_user)));
        console2.log("GVC balance after", IERC20(GVC).balanceOf(address(_user)));
        console2.log("ETH balance after", address(_user).balance);
        console2.log("BabyDoge balance after", IERC20(BabyDoge).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    // function test_swapUSDCtoBUSD() public user(bob) tokenBalance(bob) {
    //     deal(USDC, bob, 1 * 10 ** 18);
    //     IERC20(USDC).approve(tokenApprove, 1 * 10 ** 18);

    //     uint256 amount = IERC20(USDC).balanceOf(bob);
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
    //     swapInfo.baseRequest.toToken = BUSD;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with adapter
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(USDC_BUSD))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(address(USDC), address(BUSD));
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    // function test_swapGVCtoETH() public user(bob) tokenBalance(bob) {
    //     deal(GVC, bob, 2328.335653166 * 10 ** 18);
    //     IERC20(GVC).approve(tokenApprove, 2328.335653166 * 10 ** 18);

    //     uint256 amount = IERC20(GVC).balanceOf(bob);
    //     SwapInfo memory swapInfo;
    //     swapInfo.baseRequest.fromToken = uint256(uint160(address(GVC)));
    //     swapInfo.baseRequest.toToken = ETH;
    //     swapInfo.baseRequest.fromTokenAmount = amount;
    //     swapInfo.baseRequest.minReturnAmount = 0;
    //     swapInfo.baseRequest.deadLine = block.timestamp;

    //     swapInfo.batchesAmount = new uint[](1);
    //     swapInfo.batchesAmount[0] = amount;

    //     swapInfo.batches = new DexRouter.RouterPath[][](1);
    //     swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    //     swapInfo.batches[0][0].mixAdapters = new address[](1);
    //     swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
    //     swapInfo.batches[0][0].assetTo = new address[](1);
    //     // direct interaction with adapter
    //     swapInfo.batches[0][0].assetTo[0] = address(adapter);
    //     swapInfo.batches[0][0].rawData = new uint[](1);
    //     swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(GVC_WETH))));
    //     swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
    //     swapInfo.batches[0][0].extraData[0] = abi.encode(address(GVC), address(ETH));
    //     swapInfo.batches[0][0].fromToken = uint256(uint160(address(GVC)));

    //     swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    //     dexRouter.smartSwapByOrderId(
    //         swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
    //     );
    // }

    function test_swapETHtoBabydoge() public user(bob) tokenBalance(bob) {
        deal(bob, 0.063 ether);

        uint256 amount = 0.063 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ETH)));
        swapInfo.baseRequest.toToken = BabyDoge;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(BabyDoge_WETH))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(ETH), address(BabyDoge));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId{value: 0.063 ether}(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}

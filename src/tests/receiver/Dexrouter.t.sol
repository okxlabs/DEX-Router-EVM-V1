// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import {CustomERC20} from "../common/mock/MeMeERC20.sol";
import "@dex/interfaces/IUnswapRouter02.sol";
import "@dex/interfaces/IUni.sol";
import "@dex/interfaces/IUniswapV2Factory.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DexRouterTest is Test {
    DexRouter dexRouter;
    address admin = 0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87;
    address alice = vm.rememberKey(1);
    address bob = vm.rememberKey(2);
    IApproveProxy tokenApproveProxy = IApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58);
    address relayer = 0x5703B683c7F928b721CA95Da988d73a3299d4757;
    address APPROVE_PROXY = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address USDC_USDT_V2 = 0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f;
    address WETH_USDC_V2 = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address WETH_USDT_V2 = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;

    address WETH_UDSC_V3 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address WETH_USDT_V3 = 0x11b815efB8f581194ae79006d24E0d814B7697F6;
    address USDC_USDT_V3 = 0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf;

    address DNY_ADAPTER = 0x031F1aD10547b8dEB43A36e5491c06A93812023a;
    IUnswapRouter02 uniV2Router = IUnswapRouter02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    IUniswapV2Factory factory = IUniswapV2Factory(payable(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f));

    address MOON;
    address SAFE_WETH;


    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 18482816);
        
        vm.startPrank(admin);
        vm.deal(admin, 100 ether);
        dexRouter = new DexRouter();
        TransparentUpgradeableProxy proxy =
        new TransparentUpgradeableProxy(address(dexRouter), address(admin), abi.encodeWithSelector(DexRouter.initialize.selector));
        dexRouter = DexRouter(payable(address(proxy)));
        tokenApproveProxy.addProxy(address(dexRouter));
        CustomERC20 safemoon = new CustomERC20(admin,1000_000 ether, "safemoon", "safemoon", uint8(18), 500,500,address(1),true);
        safemoon.mint(admin, 100 ether);
        safemoon.approve(address(uniV2Router), type(uint256).max);
        uniV2Router.addLiquidityETH{value: 100 ether}(address(safemoon), 100 ether, 0, 0, admin, block.timestamp);
        SAFE_WETH = factory.getPair(address(safemoon), WETH);
        MOON = address(safemoon);
        require(WETH == IUni(SAFE_WETH).token0(), "must be token0");
        require(MOON == IUni(SAFE_WETH).token1(), "must be token1");
        safemoon.mint(bob, 100 ether);
        vm.stopPrank();

        vm.label(bob, "bob");
        vm.label(alice, "alice");
        vm.deal(alice, 100 ether);
        
        vm.startPrank(alice);
        IERC20(WETH).approve(APPROVE_PROXY, type(uint256).max);
        IERC20(USDC).approve(APPROVE_PROXY, type(uint256).max);
        vm.stopPrank();
        
        vm.startPrank(0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6);
        address[] memory caller = new address[](1);
        caller[0] = address(dexRouter);
        relayer.call(abi.encodeWithSignature("setCallerOk(address[],bool)", caller, true));
        vm.stopPrank();
        
        
    }

    modifier payer(address _user, address _token, uint256 _amount) {
        vm.startPrank(_user);
        deal(_token, _user, _amount);
        IERC20(_token).approve(APPROVE_PROXY, _amount);
        console2.log("%s user: Alice amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));
        _;
        console2.log("%s user: Alice amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));

        vm.stopPrank();
    }

    modifier receiver(address _user, address _token) {
        console2.log("%s user: Bob   amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));
        _;
        console2.log("%s user: Bob   amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));
    }

    struct UnxV2Info {
        uint256 srcToken;
        uint256 amount;
        uint256 minReturn;
        address receiver;
        bytes32[] pools;
    }
    // MOON: token1; WETH: token0; swapMoonForWETH: swap 1 to 0
    function test_unxswapToSafeMoonForWETH() public payer(alice, MOON, 1 ether) receiver(bob, WETH) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(MOON)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 10000;
        info.receiver = bob;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80+0x20), uint56(0), uint32(997000000), address(SAFE_WETH)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    // MOON: token1; WETH: token0; swapMoonForWETH: swap 1 to 0
    function test_unxswapToSafeMoonForETH() public payer(alice, MOON, 1 ether) receiver(bob, WETH) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(MOON)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 10000;
        info.receiver = bob;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80+0x20+0x40), uint56(0), uint32(997000000), address(SAFE_WETH)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    // MOON: token1; WETH: token0; swap 0 to 1
    function test_unxswapToSafeMoon() public payer(alice, WETH, 1 ether) receiver(bob, MOON) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(WETH)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 0.1 ether;
        info.receiver = bob;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x00+0x20), uint56(0), uint32(997000000), address(SAFE_WETH)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    // swap USDC for WETH, swap WETH for MOON
    function test_unxswapToSafeMoonJump() public payer(alice, USDC, 2000*10**6) receiver(bob, MOON) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(USDC)) + (1 << 160);
        info.amount = 2000*10**6;
        info.minReturn = 0.1 ether;
        info.receiver = bob;
        info.pools = new bytes32[](2); // USDC->WETH->MOON
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997000000), address(WETH_USDC_V2)));
        info.pools[1] = bytes32(abi.encodePacked(uint8(0x00+0x20), uint56(0), uint32(997000000), address(SAFE_WETH)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    // swap MOON for WETH, swap WETH for USDC
    function test_unxswapToSafeMoonJump2() public payer(alice, MOON, 1 ether) receiver(bob, USDC) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(MOON)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 1000_000_000;
        info.receiver = bob;
        info.pools = new bytes32[](2); // MOON->WETH->USDC
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80+0x20), uint56(0), uint32(997000000), address(SAFE_WETH)));
        info.pools[1] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(WETH_USDC_V2)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    

    function test_unxswapTo() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(WETH)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 0;
        info.receiver = bob;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(WETH_USDC_V2)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    function test_unxswapToFromETH() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(0)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 0;
        info.receiver = bob;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(WETH_USDC_V2)));
        dexRouter.unxswapTo{value: 1 ether}(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }
    function test_unxswapToETH() public payer(alice, USDC, 10**6 ) receiver(bob, USDC) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(USDC)) + (1 << 160);
        info.amount = 10**6;
        info.minReturn = 0;
        info.receiver = bob;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x40), uint56(0), uint32(997000000), address(WETH_USDC_V2)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }

    function test_unxswapToJump() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(WETH)) + (1 << 160);
        info.amount = 1 ether;
        info.minReturn = 0;
        info.receiver = bob;
        info.pools = new bytes32[](2); // WETH->USDT->USDC
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997000000), address(WETH_USDT_V2)));
        info.pools[1] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(USDC_USDT_V2)));
        dexRouter.unxswapTo(info.srcToken, info.amount, info.minReturn, info.receiver, info.pools);
    }

    function test_unxswapToJumpCommission() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        UnxV2Info memory info;
        info.srcToken = uint256(uint160(WETH)) + (1 << 160);
        info.amount = 1 ether * 0.97 ether / 1 ether;
        info.minReturn = 0;
        info.receiver = bob;
        info.pools = new bytes32[](2); // WETH->USDT->USDC
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997000000), address(WETH_USDT_V2)));
        info.pools[1] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(USDC_USDT_V2)));
        bytes memory data = abi.encodePacked(
            abi.encodeWithSelector(
                dexRouter.unxswapTo.selector, info.srcToken, info.amount, info.minReturn, info.receiver, info.pools
            ),
            bytes32(abi.encodePacked(bytes6(0x3ca20afc2aaa), uint48(300), address(address(this))))
        );
        (bool s, bytes memory t) = address(dexRouter).call(data);
        console2.log("WETH commission amount", IERC20(WETH).balanceOf(address(this)));
        require(s, string(t));
    }


    struct SmartSwapInfo {
        uint256 orderId;
        address receiver;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_smartswapTo() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        SmartSwapInfo memory info;
        info.orderId = 0;
        info.receiver = bob;
        info.baseRequest.fromToken = uint256(uint160(WETH));
        info.baseRequest.toToken = USDC;
        info.baseRequest.fromTokenAmount = 1 ether;
        info.baseRequest.minReturnAmount = 0;
        info.baseRequest.deadLine = block.timestamp;
        info.batchesAmount = new uint[](1);
        info.batchesAmount[0] = 1 ether;
        info.batches = new DexRouter.RouterPath[][](1);
        info.batches[0] = new DexRouter.RouterPath[](1);
        info.batches[0][0].mixAdapters = new address[](1);
        info.batches[0][0].mixAdapters[0] = DNY_ADAPTER;
        info.batches[0][0].assetTo = new address[](1);
        info.batches[0][0].assetTo[0] = WETH_USDC_V2;
        info.batches[0][0].rawData = new uint[](1);
        info.batches[0][0].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WETH_USDC_V2))));
        info.batches[0][0].extraData = new bytes[](1);
        info.batches[0][0].extraData[0] = abi.encode(30);
        info.batches[0][0].fromToken = uint256(uint160(WETH));
        info.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapTo(
            info.orderId, info.receiver, info.baseRequest, info.batchesAmount, info.batches, info.extraData
        );
    }

    function test_smartswapToJump() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        SmartSwapInfo memory info;
        info.orderId = 0;
        info.receiver = bob;
        info.baseRequest.fromToken = uint256(uint160(WETH));
        info.baseRequest.toToken = USDC;
        info.baseRequest.fromTokenAmount = 1 ether;
        info.baseRequest.minReturnAmount = 0;
        info.baseRequest.deadLine = block.timestamp;
        info.batchesAmount = new uint[](1);
        info.batchesAmount[0] = 1 ether;
        info.batches = new DexRouter.RouterPath[][](1);
        info.batches[0] = new DexRouter.RouterPath[](2);
        info.batches[0][0].mixAdapters = new address[](1);
        info.batches[0][0].mixAdapters[0] = DNY_ADAPTER;
        info.batches[0][0].assetTo = new address[](1);
        info.batches[0][0].assetTo[0] = WETH_USDT_V2;
        info.batches[0][0].rawData = new uint[](1);
        info.batches[0][0].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(WETH_USDT_V2))));
        info.batches[0][0].extraData = new bytes[](1);
        info.batches[0][0].extraData[0] = abi.encode(30);
        info.batches[0][0].fromToken = uint256(uint160(WETH));
        info.batches[0][1].mixAdapters = new address[](1);
        info.batches[0][1].mixAdapters[0] = DNY_ADAPTER;
        info.batches[0][1].assetTo = new address[](1);
        info.batches[0][1].assetTo[0] = USDC_USDT_V2;
        info.batches[0][1].rawData = new uint[](1);
        info.batches[0][1].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(USDC_USDT_V2))));
        info.batches[0][1].extraData = new bytes[](1);
        info.batches[0][1].extraData[0] = abi.encode(30);
        info.batches[0][1].fromToken = uint256(uint160(USDC));
        
        info.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapTo(
            info.orderId, info.receiver, info.baseRequest, info.batchesAmount, info.batches, info.extraData
        );
    }

    function test_smartswapToCommission() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        SmartSwapInfo memory info;
        info.orderId = 0;
        info.receiver = bob;
        info.baseRequest.fromToken = uint256(uint160(WETH));
        info.baseRequest.toToken = USDC;
        info.baseRequest.fromTokenAmount = 0.97 ether;
        info.baseRequest.minReturnAmount = 0;
        info.baseRequest.deadLine = block.timestamp;
        info.batchesAmount = new uint[](1);
        info.batchesAmount[0] = 0.97 ether;
        info.batches = new DexRouter.RouterPath[][](1);
        info.batches[0] = new DexRouter.RouterPath[](1);
        info.batches[0][0].mixAdapters = new address[](1);
        info.batches[0][0].mixAdapters[0] = DNY_ADAPTER;
        info.batches[0][0].assetTo = new address[](1);
        info.batches[0][0].assetTo[0] = WETH_USDC_V2;
        info.batches[0][0].rawData = new uint[](1);
        info.batches[0][0].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(WETH_USDC_V2))));
        info.batches[0][0].extraData = new bytes[](1);
        info.batches[0][0].extraData[0] = abi.encode(30);
        info.batches[0][0].fromToken = uint256(uint160(WETH));
        info.extraData = new PMMLib.PMMSwapRequest[](0);
        bytes memory data = abi.encodePacked(
            abi.encodeWithSelector(
                dexRouter.smartSwapTo.selector,
                info.orderId,
                info.receiver,
                info.baseRequest,
                info.batchesAmount,
                info.batches,
                info.extraData
            ),
            bytes32(abi.encodePacked(bytes6(0x3ca20afc2aaa), uint48(300), address(address(this))))
        );
        (bool s, bytes memory t) = address(dexRouter).call(data);
        require(s, string(t));
        console2.log("WETH commission amount", IERC20(WETH).balanceOf(address(this)));
    }

    struct UniV3Info {
        uint256 recipient;
        uint256 amount;
        uint256 minReturn;
        uint256[] pools;
    }

    function test_unxswapV3To() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        UniV3Info memory info;
        info.recipient = uint160(bob);
        info.amount = 1 ether;
        info.minReturn = 0;
        info.pools = new uint[](1);
        info.pools[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(WETH_UDSC_V3))));
        dexRouter.uniswapV3SwapTo(info.recipient, info.amount, info.minReturn, info.pools);
    }

    function test_unxswapV3ToJump() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        SafeERC20.safeApprove(IERC20(USDT), APPROVE_PROXY, type(uint256).max);
        UniV3Info memory info;
        info.recipient = uint160(bob);
        info.amount = 1 ether;
        info.minReturn = 0;
        info.pools = new uint[](2);
        info.pools[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997000000), address(WETH_USDT_V3))));
        info.pools[1] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(USDC_USDT_V3))));
        dexRouter.uniswapV3SwapTo(info.recipient, info.amount, info.minReturn, info.pools);
    }

    function test_unxswapV3ToJumpCommission() public payer(alice, WETH, 1 ether) receiver(bob, USDC) {
        SafeERC20.safeApprove(IERC20(USDT), APPROVE_PROXY, type(uint256).max);
        UniV3Info memory info;
        info.recipient = uint160(bob);
        info.amount = 0.97 ether;
        info.minReturn = 0;
        info.pools = new uint[](2);
        info.pools[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997000000), address(WETH_USDT_V3))));
        info.pools[1] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997000000), address(USDC_USDT_V3))));
        bytes memory data = abi.encodePacked(
            abi.encodeWithSelector(
                dexRouter.uniswapV3SwapTo.selector, info.recipient, info.amount, info.minReturn, info.pools
            ),
            bytes32(abi.encodePacked(bytes6(0x3ca20afc2aaa), uint48(300), address(address(this))))
        );
        (bool s, bytes memory t) = address(dexRouter).call(data);
        require(s, string(t));
        console2.log("WETH commission amount", IERC20(WETH).balanceOf(address(this)));
    }
    receive() external payable {}
}

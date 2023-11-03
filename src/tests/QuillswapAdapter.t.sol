// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "@dex/DexRouter.sol";
import "@dex/libraries/SafeERC20.sol";

contract QuillswapAdapterTest is Test {
    address USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address WETH = 0x5300000000000000000000000000000000000004;
    address USDC_WETH = 0x3109Cd8cFB11931974F916F68F790661e29D023A;
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address bob = vm.rememberKey(1);
    

    function setUp() public {
        vm.createSelectFork("SCROLL_RPC_URL", 147120);
    }
    struct SwapInfo{
        uint256 srcToken;
        uint256 amount;
        uint256 minReturn;
        bytes32[] pools;
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(_user)));
        _;
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(_user)));
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(_user)));
    }

    function test_swapUSDCForWETH() public user(bob) tokenBalance(bob) {
        deal(USDC, bob, 1 * 10 ** 6);
        IERC20(USDC).approve(tokenApprove, 1 * 10 ** 6);

        SwapInfo memory info;
        info.srcToken = uint256(uint160(USDC));
        info.amount = 1 * 10 ** 6;
        info.minReturn = 0;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997500000), address(USDC_WETH)));
        dexRouter.unxswapByOrderId(info.srcToken, info.amount, info.minReturn, info.pools);
    }

    function test_swapWETHForUSDC() public user(bob) tokenBalance(bob) {
        deal(WETH, bob, 1 ether);
        IERC20(WETH).approve(tokenApprove, 1 ether);

        SwapInfo memory info;
        info.srcToken = uint256(uint160(WETH));
        info.amount = 1 ether;
        info.minReturn = 0;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997500000), address(USDC_WETH)));
        dexRouter.unxswapByOrderId(info.srcToken, info.amount, info.minReturn, info.pools);
    }
}
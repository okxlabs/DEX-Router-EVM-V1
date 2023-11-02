pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/libraries/SafeERC20.sol";

contract PunkSwapAdapterTest is Test {
    address PUNK = 0xDdEB23905F6987d5f786A93C00bBED3d97Af1ccc;
    address USDT = 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df;
    address PUNK_USDT = 0x31f1F9f19f0bA2d88704DC0fA4Fcba553ADf280b;
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address alice = vm.rememberKey(1);

    struct SwapInfo {
        uint256 srcToken;
        uint256 amount;
        uint256 minReturn;
        bytes32[] pools;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("SCROLL_RPC_URL"), 147120);
    }
    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance() {
        console2.log("PUNK balance before", IERC20(PUNK).balanceOf(address(alice)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(alice)));
        _;
        console2.log("PUNK balance after", IERC20(PUNK).balanceOf(address(alice)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(alice)));
    }
    // PUNK -> USDT, 0->1

    function test_swapPunkForUSDT() public user(alice) tokenBalance {
        deal(PUNK, alice, 1 ether);
        IERC20(PUNK).approve(tokenApprove, 1 ether);

        SwapInfo memory info;
        info.srcToken = uint256(uint160(PUNK));
        info.amount = 1 ether;
        info.minReturn = 0;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(997500000), address(PUNK_USDT)));
        dexRouter.unxswapByOrderId(info.srcToken, info.amount, info.minReturn, info.pools);
    }

    // USDT -> PUNK, 1->0
    function test_swapUSDTForPunk() public user(alice) tokenBalance {
        deal(USDT, alice, 1 * 10 ** 6);
        SafeERC20.safeApprove(IERC20(USDT), tokenApprove, 1 * 10 ** 6);

        SwapInfo memory info;
        info.srcToken = uint256(uint160(USDT));
        info.amount = 1 * 10 ** 6;
        info.minReturn = 0;
        info.pools = new bytes32[](1);
        info.pools[0] = bytes32(abi.encodePacked(uint8(0x80), uint56(0), uint32(997500000), address(PUNK_USDT)));
        dexRouter.unxswapByOrderId(info.srcToken, info.amount, info.minReturn, info.pools);
    }
}
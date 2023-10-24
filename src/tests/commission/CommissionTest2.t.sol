pragma solidity ^0.8.0;

import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";
import "@dex/TokenApproveProxy.sol";
import "forge-std/test.sol";
import "forge-std/console2.sol";

contract CommissionTest2 is Test {
    DexRouter dexRouter;
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    address alice = vm.rememberKey(1);
    address referrerAddress = vm.rememberKey(2);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH_USDC = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address adapter = 0x03F911AeDc25c770e701B8F563E8102CfACd62c0; //UniV3Adapter
    address admin = 0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87;
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58);


    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 18382778);
        vm.startPrank(admin);
        dexRouter = new DexRouter();
        tokenApproveProxy.addProxy(address(dexRouter));
        vm.stopPrank();

        vm.startPrank(alice);
        IERC20(WETH).approve(tokenApprove, type(uint256).max);
        IERC20(USDC).approve(tokenApprove, type(uint256).max);
        vm.stopPrank();
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    function getSmartSwapCalldata(uint256 amount) public view returns (bytes memory) {
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(WETH));
        swapInfo.baseRequest.toToken = USDC;
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
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(false, uint88(10000), address(WETH_USDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(0, abi.encode(WETH, USDC, 500));
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        return abi.encodeWithSelector(
            DexRouter.smartSwapByOrderId.selector,
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_swapWETHForUSDC() public user(alice) {
        deal(WETH, alice, 1 ether);

        address user = alice;

        console2.log("USDC balance before", IERC20(USDC).balanceOf(user));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(user));

        uint256 amount = IERC20(WETH).balanceOf(user);

        uint256 id = vm.snapshot();

        (bool success, bytes memory res) = address(dexRouter).call(getSmartSwapCalldata(amount));
        require(success, string(res));

        console2.log("WETH balance after swap", IERC20(WETH).balanceOf(user));
        console2.log("USDC balance after swap", IERC20(USDC).balanceOf(user));
        console2.log("===========");
        vm.revertTo(id);

        (success, res) = address(dexRouter).call(
            abi.encodePacked(
                getSmartSwapCalldata(amount * 9700 / 10000),
                bytes32(abi.encodePacked(bytes6(0x3ca20afc2aaa), uint48(300), address(referrerAddress)))
            )
        );
        require(success, string(res));
        console2.log("WETH balance after swap", IERC20(WETH).balanceOf(user));
        console2.log("USDC balance after swap", IERC20(USDC).balanceOf(user));

        console2.log("WETH balance after swap refer", IERC20(WETH).balanceOf(referrerAddress));
    }
}
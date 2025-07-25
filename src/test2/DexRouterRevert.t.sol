// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/TestRevertAdapter.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/TokenApprove.sol";
import "@dex/interfaces/IERC20.sol";

contract DexRouterRevert is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    DexRouter dexRouter;
    TestRevertAdapter testAdapter;
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58);
    TokenApprove tokenApprove = TokenApprove(0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f);

    address alice = vm.rememberKey(11111);
    address tokenApproveProxyAdmin = 0xAcE2B3E7c752d5deBca72210141d464371b3B9b1;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 22986013);
        dexRouter = new DexRouter();
        testAdapter = new TestRevertAdapter();
        vm.startPrank(tokenApproveProxyAdmin);
        tokenApproveProxy.addProxy(address(dexRouter));
        vm.stopPrank();
    }

    modifier user(address _user, address _token, uint256 _amount) {
        vm.startPrank(_user);
        deal(_token, _user, _amount);
        IERC20(_token).approve(address(tokenApprove), _amount);
        _;
        vm.stopPrank();
    }

    function test_revert_flag1() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(1);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    function test_revert_flag2() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(2);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    function test_revert_flag3() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(3);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    function test_revert_flag4() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(4);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    function test_revert_flag5() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(5);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    function test_revert_flag6() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(6);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    function test_revert_flag7() public user(alice, WETH, 1) {
        SwapInfo memory swapInfo = _genSwapInfo(7);
        vm.expectRevert();
        dexRouter.smartSwapByOrderId(swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData);
    }

    // ==================== Internal Functions ====================
    function _genSwapInfo(uint256 flag) internal view returns (SwapInfo memory swapInfo) {
        swapInfo.baseRequest.fromToken = uint256(uint160(WETH));
        swapInfo.baseRequest.toToken = BNB;
        swapInfo.baseRequest.fromTokenAmount = 1;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = 1;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(testAdapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with adapter
        swapInfo.batches[0][0].assetTo[0] = address(testAdapter); 
        swapInfo.batches[0][0].rawData = new uint[](1);
        // The constant 10000 was used in the original rawData encoding. 
        // If this value (e.g., fee tier or other parameter) needs to be dynamic, 
        // it should be passed as a parameter as well.
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(0))));
        swapInfo.batches[0][0].extraData = new bytes[](1); 
        swapInfo.batches[0][0].extraData[0] = abi.encode(flag);
        swapInfo.batches[0][0].fromToken = uint256(uint160(WETH));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        
        return swapInfo;
    }
}
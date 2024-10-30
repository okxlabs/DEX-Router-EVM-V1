// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/HashflowV3Adapter.sol";
import "@dex/interfaces/IHashflowV3.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract HashflowV3AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xF3dE3C0d654FDa23daD170f0f320a92172509127));
    address tokenApprove = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address router = 0x55084eE0fEf03f14a305cd24286359A35D735151;

    address pool = 0x012cb12e94bF2F3079952A99D6441BDa44db23e7;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address bob = 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad;

    address externalAccount = 0x829F3Eb4ca4F7519228a79f5B0CDC45B4E58D40c;
    uint256 effectiveBaseTokenAmount = 0;
    uint256 baseTokenAmount = 1000000000000000;
    uint256 quoteTokenAmount = 2953555669799661700;
    uint256 quoteExpiry = 1715654228;
    uint256 nonce = 1715654187972;
    bytes32 txid = 0x1000000cc000cc00010cbcdb6dc5e0ffffffffffffff0020168e73d33c9a0000;
    bytes signature;

    HashflowV3Adapter adapter;

    function setUp() public {
        //https://etherscan.io/tx/0x511a8c24118510bd1b1dbdd20e48a73b5d1d3e50c05c9738d1f76bcfc49e6830

        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 19865311 - 1);
        // adapter = new HashflowV3Adapter(payable(router), WETH);
        adapter = HashflowV3Adapter(payable(0xFA574f8B3152504E391E53FfF6e55E3Ee56e0889));
        signature = hex"16191a66ca2ceae73d7c1a39707eaddef6fb09324400758ff47f697a4cd0861d2b62c6e1c9a14240d5161ebbf1418599f70e3a60a800f2482898c722115c0dc31c";
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address _user) {
        console2.log("DAI balance before", IERC20(DAI).balanceOf(address(_user)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(_user)));
        _;
        console2.log("DAI balance after", IERC20(DAI).balanceOf(address(_user)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(_user)));
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_swapWETHtoDAI() public user(bob) tokenBalance(bob) {
        deal(WETH, bob, 0.001 ether);
        IERC20(WETH).approve(tokenApprove, 0.001 ether);
        uint256 amount = 0.001 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
        swapInfo.baseRequest.toToken = DAI;
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
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(pool))));
        swapInfo.batches[0][0].extraData = new bytes[](1);//extradata is 0x
        RFQTQuote memory quoteInfo = RFQTQuote({
            pool: pool,
            externalAccount: externalAccount,
            trader: bob,
            effectiveTrader: bob,
            baseToken: WETH,
            quoteToken: DAI,
            effectiveBaseTokenAmount: effectiveBaseTokenAmount,
            baseTokenAmount: baseTokenAmount,
            quoteTokenAmount: quoteTokenAmount,
            quoteExpiry: quoteExpiry,
            nonce: nonce,
            txid: txid,
            signature: signature
        });
        swapInfo.batches[0][0].extraData[0] = abi.encode(address(WETH), address(DAI), quoteInfo);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId, swapInfo.baseRequest, swapInfo.batchesAmount, swapInfo.batches, swapInfo.extraData
        );
    }

}

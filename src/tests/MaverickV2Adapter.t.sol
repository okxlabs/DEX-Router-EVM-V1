pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/MaverickV2Adapter.sol";

contract MaverickV2AdapterTest is Test {
    MaverickV2Adapter public adapter;
    DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));   // arb
    address payable WETH = payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address USDC_USDT = 0xA3E5FD4bAC58e51eb7893F3e1BdD19A85eb67173;
    address WETH_USDC = 0x71cB8A26F2c4EB68288bcC2eBaBA4F72b065f076;
    address morty = vm.rememberKey(1); 

    function setUp() public {
        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        // adapter = new MaverickV2Adapter(WETH);
        adapter = new MaverickV2Adapter();
        console2.log("Adapter address", address(adapter));
    }

    function test_adapter_USDC_USDT() public {
        deal(USDC, address(this), 10 * 10 ** 6);
        console2.log("test USDC before amount", IERC20(USDC).balanceOf(address(this)));
        console2.log("test USDT before amount", IERC20(USDT).balanceOf(address(this)));

        IERC20(USDC).transfer(address(adapter), 2 * 10 ** 6);

        adapter.sellBase(
            address(this),
            USDC_USDT,
            abi.encode(USDC, USDT)
        );
        console2.log("test USDC after amount", IERC20(USDC).balanceOf(address(this)));
        console2.log("test USDT after amount", IERC20(USDT).balanceOf(address(this)));
    }

    function test_adapter_USDT_USDC() public {
        deal(USDT, address(this), 10 * 10 ** 6);
        console2.log("test USDC before amount", IERC20(USDC).balanceOf(address(this)));
        console2.log("test USDT before amount", IERC20(USDT).balanceOf(address(this)));

        IERC20(USDT).transfer(address(adapter), 2 * 10 ** 6);

        adapter.sellQuote(
            address(this),
            USDC_USDT,
            abi.encode(USDT, USDC)
        );
        console2.log("test USDC after amount", IERC20(USDC).balanceOf(address(this)));
        console2.log("test USDT after amount", IERC20(USDT).balanceOf(address(this)));
    }

    function test_adapter_WETH_USDC() public {
        deal(WETH, address(this), 1 * 10 ** 18);
        console2.log("test USDC before amount", IERC20(USDC).balanceOf(address(this)));
        console2.log("test WETH before amount", IERC20(WETH).balanceOf(address(this)));

        IERC20(WETH).transfer(address(adapter), 0.0005 * 10 ** 18);

        adapter.sellBase(
            address(this),
            WETH_USDC,
            abi.encode(WETH, USDC)
        );
        console2.log("test USDC after amount", IERC20(USDC).balanceOf(address(this)));
        console2.log("test WETH after amount", IERC20(WETH).balanceOf(address(this)));
    }

    struct SwapInfo {
        uint orderId;
        DexRouter.BaseRequest baseRequest;
        uint[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        _;
        vm.stopPrank();
    }

    modifier tokenBalance(address fromToken, uint256 amount) {
        deal(fromToken, morty, amount);
        console2.log("USDC balance before", IERC20(USDC).balanceOf(address(morty)));
        console2.log("USDT balance before", IERC20(USDT).balanceOf(address(morty)));
        console2.log("WETH balance before", IERC20(WETH).balanceOf(address(morty)));
        _;
        console2.log("USDC balance after", IERC20(USDC).balanceOf(address(morty)));
        console2.log("USDT balance after", IERC20(USDT).balanceOf(address(morty)));
        console2.log("WETH balance after", IERC20(WETH).balanceOf(address(morty)));
    }

    function test_integrate_usdc_usdt() public user(morty) tokenBalance(USDC, 100 * 10 ** 6) {
        uint fromAmount = 2 * 10 ** 6;
        IERC20(USDC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDC));
        swapInfo.baseRequest.toToken = USDT;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        // batchesAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        // batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);

        // assetTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);

        // rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(
                abi.encodePacked(
                    uint8(0x00), 
                    uint88(10000), 
                    address(USDC_USDT)
                )
            )
        );

        // moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, USDT);

        // fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_integrate_weth_usdc() public user(morty) tokenBalance(WETH, 10 * 10 ** 18) {
        uint fromAmount = 0.0005 * 10 ** 18;
        IERC20(WETH).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));
        swapInfo.baseRequest.toToken = USDC;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        // batchesAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        // batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);

        // assetTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);

        // rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(
                abi.encodePacked(
                    uint8(0x00), 
                    uint88(10000), 
                    address(WETH_USDC)
                )
            )
        );

        // moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(WETH, USDC);

        // fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function test_integrate_usdc_weth() public user(morty) tokenBalance(USDC, 10 * 10 ** 6) {
        uint fromAmount = 1 * 10 ** 6;
        IERC20(USDC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDC));
        swapInfo.baseRequest.toToken = WETH;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        // batchesAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        // batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // mixAdapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);

        // assetTo
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);

        // rawData
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint(
            bytes32(
                abi.encodePacked(
                    uint8(0x00), 
                    uint88(10000), 
                    address(WETH_USDC)
                )
            )
        );

        // moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(USDC, WETH);

        // fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(USDC)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }
}
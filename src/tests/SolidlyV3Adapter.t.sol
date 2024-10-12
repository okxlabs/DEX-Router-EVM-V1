pragma solidity 0.8.17;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/SolidlyV3Adapter.sol";


contract SolidlyV3AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xf332761c673b59B21fF6dfa8adA44d78c12dEF09));       // arb
    SolidlyV3Adapter adapter;
    address tokenApprove = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address pool = 0xaDF56F4966f965d1759ecD3D63028d610E773817;      // usdc-usdt
    address morty = vm.rememberKey(1);

    function setUp() public {
        vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        deal(USDC, address(this), 100 * 10 ** 6);
        deal(USDT, address(this), 100 * 10 ** 6);
        adapter = new SolidlyV3Adapter();
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
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(morty)));
        console2.log("USDT balance before",IERC20(USDT).balanceOf(address(morty)));
        _;
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(morty)));
        console2.log("USDT balance after",IERC20(USDT).balanceOf(address(morty)));
    }

    function test_single() public {
        console2.log("USDC beforeswap balance", IERC20(USDC).balanceOf(address(this)));
        console2.log("USDT beforeswap balance", IERC20(USDT).balanceOf(address(this)));
        IERC20(USDC).transfer(address(adapter), 10 * 10 ** 6);

        // moreInfo
        uint24 fee = 0;
        address fromToken = USDC;
        address toToken = USDT;
        uint160 sqrtPriceLimitX96 = 0;
        bytes memory moreInfo = abi.encode(
            sqrtPriceLimitX96, 
            abi.encode(
                fromToken, 
                toToken, 
                fee
            )
        );

        adapter.sellBase(address(this), pool, moreInfo);
        console2.log("USDC afterswap balance", IERC20(USDC).balanceOf(address(this)));
        console2.log("USDT afterswap balance", IERC20(USDT).balanceOf(address(this)));
    }

    function test_integrate() public user(morty) tokenBalance(USDC, 100 * 10 ** 6) {
        uint fromAmount = 10 * 10 ** 6;
        IERC20(USDC).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(USDC));
        swapInfo.baseRequest.toToken = USDT;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        // batchsAmount
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
                    address(pool)
                )
            )
        );

        // moreInfo
        uint24 fee = 0;
        address fromToken = USDC;
        address toToken = USDT;
        uint160 sqrtPriceLimitX96 = 0;
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            sqrtPriceLimitX96, 
            abi.encode(
                fromToken, 
                toToken, 
                fee
            )
        );

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
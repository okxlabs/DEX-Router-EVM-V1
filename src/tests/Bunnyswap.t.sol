pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/BunnyswapAdapter.sol";

contract BunnyswapAdapterTest is Test {
    BunnyswapAdapter public adapter;
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));       // base
    address payable WETH = payable(0x4200000000000000000000000000000000000006);
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address FRIEND = 0x0bD4887f7D41B35CD75DFF9FfeE2856106f86670;
    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address router = 0xBf250AE227De43deDaF01ccBFD8CC83027efc1E2;
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address pool = 0x7CfC830448484CDF830625373820241E61ef4acf;      // friend <-> eth
    // address morty = vm.rememberKey(1);
    address morty = 0x8B3997e0a91DDF63585aBbC032C406F47ad45633;

    function setUp0() public {
        // vm.createSelectFork(vm.envString("BASE_RPC_URL"), 15945099);
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));
    }

    function setUp() public {
        setUp0();
        adapter = new BunnyswapAdapter(router); 
        console2.log("adapter ", address(adapter));
        deal(WETH, address(this), 0.4*10**18);
    }

    function test_adapter() public {
        IERC20(WETH).transfer(address(adapter), 400000000000000000);
        //FRIEND.call(abi.encodeWithSignature("transfer(address,uint256)", address(adapter), 1000000000000000000));
        IERC20(WETH).balanceOf(address(adapter));
        adapter.sellQuote(address(this), router, abi.encode(0.4*10**18, 1990060297433005341162));
        console2.log("FRIEND amount", IERC20(FRIEND).balanceOf(address(this)));
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
        console2.log("FRIEND balance before",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(morty)));
        _;
        console2.log("FRIEND balance after",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(morty)));
    }

    // friend -> weth
    function test_integrate1() public user(morty) {
        console2.log("FRIEND balance before",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(morty)));
        console2.log("ETH balance before", address(morty).balance);
        uint fromAmount = 10 * 10 ** 18;
        // The FRIEND token's approve method has a whitelist check, which prevents the test contract from calling the approve method directly. 
        // To solve this issue:
        // 1. swap FRIEND tokens through an exchange yourself.
        // 2. Go to the blockchain explorer and manually approve the tokenApprove address (0x57df6092665eb6058DE53939612413ff4B09114E) for the FRIEND token.
        // In the test code, remove the line IERC20(FRIEND).approve(tokenApprove, fromAmount);
        // IERC20(FRIEND).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(FRIEND));
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
                    address(pool)
                )
            )
        );

        // moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";

        // fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(FRIEND)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log("FRIEND balance after",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(morty)));
        console2.log("ETH balance after", address(morty).balance);
    }

    // friend -> eth
    function test_integrate2() public user(morty) {
        console2.log("FRIEND balance before",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(morty)));
        console2.log("ETH balance before", address(morty).balance);
        uint fromAmount = 10 * 10 ** 18;
        // The FRIEND token's approve method has a whitelist check, which prevents the test contract from calling the approve method directly. 
        // To solve this issue:
        // 1. swap FRIEND tokens through an exchange yourself.
        // 2. Go to the blockchain explorer and manually approve the tokenApprove address (0x57df6092665eb6058DE53939612413ff4B09114E) for the FRIEND token.
        // In the test code, remove the line IERC20(FRIEND).approve(tokenApprove, fromAmount);
        // IERC20(FRIEND).approve(tokenApprove, fromAmount);
        SwapInfo memory swapInfo;

        // baseRequest
        swapInfo.baseRequest.fromToken = uint256(uint160(FRIEND));
        swapInfo.baseRequest.toToken = ETH;
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
                    address(pool)
                )
            )
        );

        // moreInfo
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";

        // fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(FRIEND)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log("FRIEND balance after",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(morty)));
        console2.log("ETH balance after", address(morty).balance);
    }

    // friend -> eth -> weth -> usdc
    function test_integrate_2Hop() public user(morty) {
        console2.log("FRIEND balance before",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance before",IERC20(WETH).balanceOf(address(morty)));
        console2.log("USDC balance before",IERC20(USDC).balanceOf(address(morty)));

        uint fromAmount = 10 * 10 ** 18;

        SwapInfo memory swapInfo;

        // baseRequest friend -> weth -> usdc
        swapInfo.baseRequest.fromToken = uint256(uint160(FRIEND));
        swapInfo.baseRequest.toToken = USDC;
        swapInfo.baseRequest.fromTokenAmount = fromAmount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        // batchesAmount
        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = fromAmount;

        // batches
        // friend -> weth
        swapInfo.batches = new DexRouter.RouterPath[][](1);             // one batch
        swapInfo.batches[0] = new DexRouter.RouterPath[](2);            // two hops
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
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = "0x";
        // fromToken
        swapInfo.batches[0][0].fromToken = uint(uint160(address(FRIEND)));


        // weth -> usdc
        // mixAdapter
        swapInfo.batches[0][1].mixAdapters = new address[](1);
        swapInfo.batches[0][1].mixAdapters[0] = address(0x1Da57aFA94200d7D195aB7Bd1da5E6cBC147680d);    // SolidlyV3Adapter
        // assetTo
        swapInfo.batches[0][1].assetTo = new address[](1);
        swapInfo.batches[0][1].assetTo[0] = address(0x1Da57aFA94200d7D195aB7Bd1da5E6cBC147680d);        // SolidlyV3Adapter
        // rawData
        swapInfo.batches[0][1].rawData = new uint[](1);
        swapInfo.batches[0][1].rawData[0] = uint(
            bytes32(
                abi.encodePacked(
                    uint8(0x00), 
                    uint88(10000), 
                    address(0x551a0e3D267bEa87048F08Cc94cc6035Ad99221b)           // SolidlyV3 weth -> usdc pool
                )
            )
        );
        // moreInfo
        uint24 fee = 0;
        address fromToken = WETH;
        address toToken = USDC;
        uint160 sqrtPriceLimitX96 = 0;
        swapInfo.batches[0][1].extraData = new bytes[](1);
        swapInfo.batches[0][1].extraData[0] = abi.encode(
            sqrtPriceLimitX96, 
            abi.encode(
                fromToken, 
                toToken, 
                fee
            )
        );
        // fromToken
        swapInfo.batches[0][1].fromToken = uint(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log("FRIEND balance after",IERC20(FRIEND).balanceOf(address(morty)));
        console2.log("WETH balance after",IERC20(WETH).balanceOf(address(morty)));
        console2.log("USDC balance after",IERC20(USDC).balanceOf(address(morty)));

    }
}
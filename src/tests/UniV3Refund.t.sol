// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/DexRouter.sol";
import "@dex/adapter/UniV3Adapter.sol";

contract UniswapV3Test is Test {
    address user = 0x07d3915Efd92a536c406F5063918d2Df0d9708e7;
    address payable okx_dexrouter =
        payable(0x7D0CcAa3Fac1e5A943c5168b6CEd828691b46B36);
    address uni_router = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address pool = 0x4416056ccF79fFD3abd99e61ccF80eA13EA4311c;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address FILM = 0xe344Fb85b4FAb79e0ef32cE77c00732CE8566244;
    address fee_collector = 0x000000fee13a103A10D593b9AE06b3e05F2E7E1c;
    address inch_router = 0x111111125421cA6dc452d289314280a0f8842A65;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address adapter = 0x03F911AeDc25c770e701B8F563E8102CfACd62c0;
    address pool_usdc = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address token_approve = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    function setUp() public {
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"),
            bytes32(
                0x1ed0d036c93beb24347dc20489b313db544d57efd72d26a0a38168c3d99409e0
            )
        );
        vm.etch(address(okx_dexrouter), address(new DexRouter()).code);
        vm.etch(
            address(adapter),
            address(new UniV3Adapter(payable(WETH))).code
        );
        vm.prank(user);
        IERC20(USDC).approve(token_approve, type(uint256).max);

        deal(USDC, user, 120000 * 10 ** 6);
        deal(WETH, user, 0);
    }
    function test_invest() public {
        deal(WETH, okx_dexrouter, 3 ether);
        uint amount = 600000 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
        swapInfo.baseRequest.toToken = FILM;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            uint160(0),
            abi.encode(address(WETH), address(FILM), uint24(3000))
        );
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        DexRouter(okx_dexrouter).smartSwapByInvest(
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData,
            user
        );
    }
    function _test_invest_with_refund() public {
        deal(WETH, okx_dexrouter, 3 ether);
        uint amount = 3 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
        swapInfo.baseRequest.toToken = FILM;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            uint160(0),
            abi.encode(address(WETH), address(FILM), uint24(3000))
        );
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        DexRouter(okx_dexrouter).smartSwapByInvestWithRefund(
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData,
            user,
            user
        );
    }

    function _test_okx() public {
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(bytes32(abi.encodePacked(bytes12(0), pool)));
        vm.prank(user, user);
        DexRouter(okx_dexrouter).uniswapV3SwapTo{value: 3 ether}(
            uint256(
                bytes32(abi.encodePacked(bytes9(0), bytes3(0x019b8d), user))
            ),
            3000000000000000000,
            390789165003,
            pools
        );
        console2.log("film balance", IERC20(FILM).balanceOf(pool));
        require(IERC20(WETH).balanceOf(user) > 2.33 ether, "not valid");
    }

    function _test_okx_unxv3() public {
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(
            bytes32(abi.encodePacked(bytes1(0x00), bytes11(0), pool_usdc))
        );
        pools[1] = uint256(bytes32(abi.encodePacked(bytes12(0), pool)));
        vm.prank(user, user);
        DexRouter(okx_dexrouter).uniswapV3SwapTo(
            uint256(
                bytes32(abi.encodePacked(bytes9(0), bytes3(0x019b8d), user))
            ),
            120000 * 10 ** 6,
            390789165003,
            pools
        );
        require(IERC20(WETH).balanceOf(user) > 2.33 ether, "not valid");
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function _test_okx_smartswap() public {
        uint256 amount = 3 ether;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(ETH_ADDRESS)));
        swapInfo.baseRequest.toToken = FILM;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            uint160(0),
            abi.encode(address(WETH), address(FILM), uint24(3000))
        );
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
        vm.prank(user, user);
        DexRouter(okx_dexrouter).smartSwapByOrderId{value: 3 ether}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    function _test_okx_smartswap_usdc() public {
        uint256 amount = 120000 * 10 ** 6;
        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(USDC)));
        swapInfo.baseRequest.toToken = FILM;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](2);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(uint8(0x80), uint88(10000), address(pool_usdc))
            )
        );
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            uint160(0),
            abi.encode(address(USDC), address(WETH), uint24(3000))
        );
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(USDC)));

        swapInfo.batches[0][1].mixAdapters = new address[](1);
        swapInfo.batches[0][1].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][1].assetTo = new address[](1);
        swapInfo.batches[0][1].assetTo[0] = address(adapter);
        swapInfo.batches[0][1].rawData = new uint256[](1);
        swapInfo.batches[0][1].rawData[0] = uint256(
            bytes32(abi.encodePacked(false, uint88(10000), address(pool)))
        );
        swapInfo.batches[0][1].extraData = new bytes[](1);
        swapInfo.batches[0][1].extraData[0] = abi.encode(
            uint160(0),
            abi.encode(address(WETH), address(FILM), uint24(3000))
        );
        swapInfo.batches[0][1].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        vm.prank(user, user);
        DexRouter(okx_dexrouter).smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }
    // {
    //   "Func": "execute",
    //   "Params": [
    //     "0x0b000604",
    //     [
    //       "0x0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000002386f26fc10000",
    //       "0x0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2002710e344fb85b4fab79e0ef32ce77c00732ce8566244000000000000000000000000000000000000000000",
    //       "0x000000000000000000000000e344fb85b4fab79e0ef32ce77c00732ce8566244000000000000000000000000000000fee13a103a10d593b9ae06b3e05f2e7e1c0000000000000000000000000000000000000000000000000000000000000019",
    //       "0x000000000000000000000000e344fb85b4fab79e0ef32ce77c00732ce856624400000000000000000000000041244656f62711cc44f2e5001a5e7a960e8cb4bb000000000000000000000000000000000000000000000000000000043b2f31db"
    //     ],
    //     "1733732445"
    //   ]
    // }

    // {
    //     "func": "execute",
    //     "params": [
    //         "0b0006040c",
    //         [
    //             "000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000d3c21bcecceda1000000",
    //             "000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000d3c21bcecceda1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2002710e344fb85b4fab79e0ef32ce77c00732ce8566244000000000000000000000000000000000000000000",
    //             "000000000000000000000000e344fb85b4fab79e0ef32ce77c00732ce8566244000000000000000000000000000000fee13a103a10d593b9ae06b3e05f2e7e1c0000000000000000000000000000000000000000000000000000000000000019",
    //             "000000000000000000000000e344fb85b4fab79e0ef32ce77c00732ce8566244000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000affc93c468c5",
    //             "000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000"
    //         ],
    //         1733812427
    //     ]
    // }
    function _test_uni() public {
        bytes memory commands = hex"0b0006040c";
        uint256 deadline = type(uint256).max;
        bytes[] memory inputs = new bytes[](5);
        // 0b => Commands.WRAP_ETH
        inputs[0] = abi.encode(address(0x02), 3 ether);
        // 00 => Commands.V3_SWAP_EXACT_IN
        bytes memory path = abi.encodePacked(WETH, bytes3(uint24(10000)), FILM);
        inputs[1] = abi.encode(address(0x02), 3 ether, uint256(0), path, false);
        // 06 => commands.PAY_PORTION
        inputs[2] = abi.encode(FILM, fee_collector, uint256(0x19));
        // 04 => commands.SWEEP
        inputs[3] = abi.encode(FILM, user, 1);
        // 0c
        inputs[4] = abi.encode(user, 0);
        console2.logBytes(
            abi.encodeWithSignature(
                "execute(bytes,bytes[],uint256)",
                commands,
                inputs,
                deadline
            )
        );
        uni_router.call{value: 3 ether}(
            abi.encodeWithSignature(
                "execute(bytes,bytes[],uint256)",
                commands,
                inputs,
                deadline
            )
        );
    }
}

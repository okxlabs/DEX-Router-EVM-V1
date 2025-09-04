// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "lib/forge-std/src/Script.sol";
import {console2} from "lib/forge-std/src/console2.sol";
import "@dex/adapter/AspectaAdapter.sol";
import "@dex/interfaces/IAspectaKeyPool.sol";
import "@dex/interfaces/IERC20.sol";
import "@dex/interfaces/IWETH.sol";
import "@dex/DexRouter.sol";
import "@dex/TokenApprove.sol";
import "@dex/libraries/PMMLib.sol";

/// @title AspectaAdapterOnChain
/// @notice Real on-chain testing script for AspectaAdapter on BSC mainnet
/// @dev This script executes real transactions on BSC mainnet with real BNB
contract AspectaAdapterOnChain is Script {
    // BSC Mainnet addresses
    address constant WBNB_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant DEX_ROUTER = 0x6015126d7D23648C2e4466693b8DeaB005ffaba8;
    address constant TOKEN_APPROVE = 0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6;
    address constant ASPECTA_POOL_ADDRESS = 0x0834f67a5882feB21B310310b03D93bA9a17Adfd;
    address constant ASPECTA_ADAPTER = 0x1e3143b9cB44170098092e53bfbCE76E1Ce53E00;

    // Test parameters
    uint256 constant BUY_AMOUNT = 0.05 ether;
    uint256 constant KEY_AMOUNT = 10;
    uint256 constant MIN_RETURN = 1;

    DexRouter dexRouter = DexRouter(payable(DEX_ROUTER));
    IERC20 wbnb = IERC20(WBNB_ADDRESS);

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOY_PRIVATE_KEY");
        vm.rememberKey(privateKey);
        require(block.chainid == 56, "Must be BSC mainnet");

        vm.startBroadcast(privateKey);
        // buyKeysTransaction();
        // sellKeysTransaction();
        vm.stopBroadcast();
    }

    /// @notice Buy keys transaction (BNB -> Keys) - calls AspectaAdapter.sellBase()
    function buyKeysTransaction() internal {
        // Approve WBNB to TokenApprove
        wbnb.approve(TOKEN_APPROVE, BUY_AMOUNT);

        // Prepare swap info
        SwapInfo memory swapInfo;

        // Setup base request - BNB to Keys
        swapInfo.baseRequest.fromToken = uint256(uint160(ETH_ADDRESS));
        swapInfo.baseRequest.toToken = ASPECTA_POOL_ADDRESS;
        swapInfo.baseRequest.fromTokenAmount = BUY_AMOUNT;
        swapInfo.baseRequest.minReturnAmount = MIN_RETURN;
        swapInfo.baseRequest.deadLine = block.timestamp + 300;

        // Setup batch amounts
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = BUY_AMOUNT;

        // Setup routing batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // Setup adapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = ASPECTA_ADAPTER;

        // Setup asset destination
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = ASPECTA_ADAPTER;

        // Setup raw data: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(
                    uint8(0x00),
                    uint88(10000),
                    ASPECTA_POOL_ADDRESS
                )
            )
        );

        // Setup extra data for AspectaAdapter.sellBase()
        // sellBase expects: (uint256 amount) - number of keys to buy
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(KEY_AMOUNT);

        swapInfo.batches[0][0].fromToken = uint256(uint160(WBNB_ADDRESS));

        // Setup PMM extra data (empty)
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        // Execute the transaction
        dexRouter.smartSwapByOrderId{value: BUY_AMOUNT}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }

    /// @notice Sell keys transaction (Keys -> BNB) through DexRouter - calls AspectaAdapter.sellQuote()
    function sellKeysTransaction() internal {
        uint256 minPrice = 0.00001 ether;
        
        // Prepare swap info for selling keys
        SwapInfo memory swapInfo;

        // Setup base request - Keys to BNB
        swapInfo.baseRequest.fromToken = uint256(uint160(ASPECTA_POOL_ADDRESS));
        swapInfo.baseRequest.toToken = ETH_ADDRESS;
        swapInfo.baseRequest.fromTokenAmount = KEY_AMOUNT;
        swapInfo.baseRequest.minReturnAmount = minPrice;
        swapInfo.baseRequest.deadLine = block.timestamp + 300;

        // Setup batch amounts
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = 0;

        // Setup routing batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // Setup adapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = ASPECTA_ADAPTER;

        // Setup asset destination
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = ASPECTA_ADAPTER;

        // Setup raw data: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(
                    uint8(0x80),
                    uint88(10000),
                    ASPECTA_POOL_ADDRESS
                )
            )
        );

        // Setup extra data for AspectaAdapter.sellQuote()
        // sellQuote expects: (uint256 amount, uint256 minPrice, uint256 fee, address feeRecipient)
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            KEY_AMOUNT,
            minPrice,
            0,
            address(0)
        );

        swapInfo.batches[0][0].fromToken = uint256(
            uint160(ASPECTA_POOL_ADDRESS)
        );

        // Setup PMM extra data (empty)
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        // Execute the transaction
        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
    }
}


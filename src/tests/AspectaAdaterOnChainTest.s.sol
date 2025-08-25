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
    address constant ASPECTA_POOL_ADDRESS =
        0x0834f67a5882feB21B310310b03D93bA9a17Adfd;
    address constant ASPECTA_ADAPTER =
        0x1e3143b9cB44170098092e53bfbCE76E1Ce53E00;

    // Test parameters
    uint256 constant BUY_AMOUNT = 0.05 ether;
    uint256 constant KEY_AMOUNT = 10;
    uint256 constant SELL_AMOUNT = 10;
    uint256 constant MIN_RETURN = 1;

    AspectaAdapter public adapter = AspectaAdapter(payable(ASPECTA_ADAPTER));
    IAspectaKeyPool public aspectaPool = IAspectaKeyPool(ASPECTA_POOL_ADDRESS);
    DexRouter public dexRouter = DexRouter(payable(DEX_ROUTER));
    IERC20 public wbnb = IERC20(WBNB_ADDRESS);

    address public user;
    uint256 public userPrivateKey;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function run() public {
        // Get deployer private key from environment and derive address
        userPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");
        user = vm.rememberKey(userPrivateKey);

        require(block.chainid == 56, "Must be BSC mainnet");

        vm.startBroadcast(userPrivateKey);

        // Uncomment to test buy and sell transactions
        // buyKeysTransaction();
        // sellKeysTransaction();
        sellKeysTransactionThroughRouter();
        vm.stopBroadcast();
    }

    function approveTokenTransfers() internal {
        // Check current allowances
        uint256 wbnbAllowance = wbnb.allowance(user, TOKEN_APPROVE);
        console2.log("Current WBNB allowance to TokenApprove:", wbnbAllowance);

        // Approve maximum amount for WBNB if needed
        if (wbnbAllowance < type(uint256).max / 2) {
            console2.log("Approving WBNB to TokenApprove...");
            wbnb.approve(TOKEN_APPROVE, type(uint256).max);
            console2.log("WBNB approval successful!");
        } else {
            console2.log("WBNB already has sufficient allowance");
        }

        console2.log("Token approvals completed");
    }

    /// @notice Buy keys transaction (BNB -> Keys) - calls AspectaAdapter.sellBase()
    function buyKeysTransaction() internal {
        approveTokenTransfers();
        console2.log("\n=== Executing Buy Keys Transaction ===");

        uint256 bnbBefore = user.balance;
        console2.log("User BNB before:", bnbBefore, "wei");

        // Prepare swap info
        SwapInfo memory swapInfo;

        // Setup base request - BNB to Keys
        swapInfo.baseRequest.fromToken = uint256(uint160(ETH_ADDRESS)); // Native BNB
        swapInfo.baseRequest.toToken = ASPECTA_POOL_ADDRESS; // Keys (pool address)
        swapInfo.baseRequest.fromTokenAmount = BUY_AMOUNT;
        swapInfo.baseRequest.minReturnAmount = MIN_RETURN;
        swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes

        // Setup batch amounts
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = BUY_AMOUNT;

        // Setup routing batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // Setup adapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);

        // Setup asset destination
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);

        // Setup raw data: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
        // reverse = 0x00 for sellBase (buy keys)
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

        console2.log("Swap amount:", BUY_AMOUNT, "wei");
        console2.log("Expected keys:", KEY_AMOUNT);

        // Execute the transaction
        uint256 returnAmount = dexRouter.smartSwapByOrderId{value: BUY_AMOUNT}(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        uint256 bnbAfter = user.balance;
        console2.log("User BNB after:", bnbAfter, "wei");
        console2.log("BNB spent:", bnbBefore - bnbAfter, "wei");
        console2.log("Return amount:", returnAmount);
        console2.log("Buy keys transaction successful!");
    }

    /// @notice Sell keys transaction (Keys -> BNB) - calls AspectaAdapter.sellQuote()
    function sellKeysTransaction() internal {
        console2.log("\n=== Selling Keys Directly ===");

        uint256 minPrice = 0.00001 ether;

        uint256 bnbBefore = user.balance;
        console2.log("User BNB before:", bnbBefore, "wei");

        // Get expected sell price
        uint256 expectedPrice = aspectaPool.getSellPrice(SELL_AMOUNT);
        console2.log("Expected BNB from selling", SELL_AMOUNT, "keys");
        console2.log("Expected price:", expectedPrice, "wei");

        console2.log("Attempting to sell", SELL_AMOUNT, "keys");
        console2.log("Minimum price:", minPrice, "wei");

        // Call sellByRouter directly
        aspectaPool.sellByRouter(SELL_AMOUNT, minPrice);

        uint256 bnbAfter = user.balance;
        console2.log("User BNB after:", bnbAfter, "wei");
        console2.log("BNB gained:", bnbAfter - bnbBefore, "wei");
        console2.log("Sell transaction successful!");
    }

    /// @notice Sell keys transaction (Keys -> BNB) through DexRouter - calls AspectaAdapter.sellQuote()
    function sellKeysTransactionThroughRouter() internal {
        console2.log("\n=== Selling Keys Through DexRouter ===");

        uint256 sellAmount = 10; // Number of keys to sell
        uint256 minPrice = 0.00001 ether; // Minimum BNB to receive

        uint256 bnbBefore = user.balance;
        console2.log("User BNB before:", bnbBefore, "wei");

        // Get expected sell price
        uint256 expectedPrice = aspectaPool.getSellPrice(sellAmount);
        

        // Prepare swap info for selling keys
        SwapInfo memory swapInfo;

        // Setup base request - Keys to BNB
        swapInfo.baseRequest.fromToken = uint256(uint160(ASPECTA_POOL_ADDRESS)); // Keys (pool address)
        swapInfo.baseRequest.toToken = ETH_ADDRESS; // Native BNB
        swapInfo.baseRequest.fromTokenAmount = sellAmount; // Number of keys
        swapInfo.baseRequest.minReturnAmount = minPrice; // Minimum BNB
        swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes

        // Setup batch amounts
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = sellAmount;

        // Setup routing batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // Setup adapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);

        // Setup asset destination
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = address(adapter);

        // Setup raw data: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
        // reverse = 0x80 for sellQuote (sell keys) - set the reverse bit
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(
                abi.encodePacked(
                    uint8(0x80), // Set reverse bit for sellQuote
                    uint88(10000), // 100% weight
                    ASPECTA_POOL_ADDRESS
                )
            )
        );

        // Setup extra data for AspectaAdapter.sellQuote()
        // sellQuote expects: (uint256 amount, uint256 minPrice, uint256 fee, address feeRecipient)
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            sellAmount, // amount of keys to sell
            minPrice, // minimum price
            0, // fee (set to 0 if no fee)
            address(0) // fee recipient (set to 0 if no fee)
        );

        swapInfo.batches[0][0].fromToken = uint256(
            uint160(ASPECTA_POOL_ADDRESS)
        );

        // Setup PMM extra data (empty)
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        console2.log("Selling", sellAmount, "keys");
        console2.log("Minimum price:", minPrice, "wei");

        // Execute the transaction (no ETH value needed for selling)
        uint256 returnAmount = dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        uint256 bnbAfter = user.balance;
        console2.log("User BNB after:", bnbAfter, "wei");
        console2.log("BNB gained:", bnbAfter - bnbBefore, "wei");
        console2.log("Return amount:", returnAmount);
        console2.log("Sell keys transaction successful!");
    }
}

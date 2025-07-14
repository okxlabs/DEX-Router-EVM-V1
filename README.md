# Dex Router

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

This repository contains the core smart contracts for the Dex Router. The router enables efficient token swaps across multiple liquidity sources and protocols through a unified interface.

## Bug bounty

This repository is subject to the OKX bug bounty program. Learn more and get started at [HackerOne](https://hackerone.com/okg/policy_scopes?type=team).

## Local Development

In order to deploy this code to a local testnet, you should install the dependencies and compile the contracts:

```bash
npm install
npx hardhat compile
```


## Using solidity Example

The router are available for import into solidity smart contracts:

```solidity
import './contracts/8/DexRouter.sol';
import './contracts/8/libraries/PMMLib.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract MyContract {
  using SafeERC20 for IERC20;
  
  DexRouter public dexRouter;
  address public tokenApprove;
  
  struct SwapInfo {
    uint256 orderId;
    DexRouter.BaseRequest baseRequest;
    uint256[] batchesAmount;
    DexRouter.RouterPath[][] batches;
    PMMLib.PMMSwapRequest[] extraData;
  }
  
  constructor(address _dexRouter, address _tokenApprove) {
    dexRouter = DexRouter(_dexRouter);
    tokenApprove = _tokenApprove;
  }

  function performTokenSwap(
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 minReturn,
    address adapter,
    address poolAddress
  ) external {
    // Step 1: Approve tokens for spending
    IERC20(fromToken).safeApprove(tokenApprove, amount);
    
    // Step 2: Prepare swap info structure
    SwapInfo memory swapInfo;
    
    // Step 3: Setup base request
    swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
    swapInfo.baseRequest.toToken = toToken;
    swapInfo.baseRequest.fromTokenAmount = amount;
    swapInfo.baseRequest.minReturnAmount = minReturn;
    swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes deadline
    
    // Step 4: Setup batch amounts
    swapInfo.batchesAmount = new uint256[](1);
    swapInfo.batchesAmount[0] = amount;
    
    // Step 5: Setup routing batches
    swapInfo.batches = new DexRouter.RouterPath[][](1);
    swapInfo.batches[0] = new DexRouter.RouterPath[](1);
    
    // Setup adapter
    swapInfo.batches[0][0].mixAdapters = new address[](1);
    swapInfo.batches[0][0].mixAdapters[0] = adapter;
    
    // Setup asset destination - tokens go to adapter
    swapInfo.batches[0][0].assetTo = new address[](1);
    swapInfo.batches[0][0].assetTo[0] = adapter;
    
    // Setup raw data with correct encoding: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
    swapInfo.batches[0][0].rawData = new uint256[](1);
    swapInfo.batches[0][0].rawData[0] = uint256(bytes32(
      abi.encodePacked(uint8(0x00), uint88(10000), poolAddress)
    ));
    
    // Setup adapter-specific extra data
    swapInfo.batches[0][0].extraData = new bytes[](1);
    swapInfo.batches[0][0].extraData[0] = abi.encode(
      bytes32(uint256(uint160(fromToken))), 
      bytes32(uint256(uint160(toToken)))
    );
    
    swapInfo.batches[0][0].fromToken = uint256(uint160(fromToken));
    
    // Step 6: Setup PMM extra data (empty for basic swaps)
    swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);
    
    // Step 7: Execute the swap
    uint256 returnAmount = dexRouter.smartSwapByOrderId(
      swapInfo.orderId,
      swapInfo.baseRequest,
      swapInfo.batchesAmount,
      swapInfo.batches,
      swapInfo.extraData
    );
    
    // returnAmount contains the actual tokens received
  }
  
  // Example: USDC to USDT swap on Ethereum mainnet
  function swapUSDCtoUSDT(uint256 amount, uint256 minReturn) external {
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address adapter = 0x...; // Your adapter address
    address poolAddress = 0x...; // Pool/LP address
    
    // Transfer tokens from user
    IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
    
    // Perform swap
    performTokenSwap(USDC, USDT, amount, minReturn, adapter, poolAddress);
    
    // Transfer result back to user
    uint256 balance = IERC20(USDT).balanceOf(address(this));
    IERC20(USDT).safeTransfer(msg.sender, balance);
  }
}
```

## Repository Structure

All contracts are held within the `contracts/8/` folder.

```
contracts/
└── 8/
    ├── DexRouter.sol               # Main aggregation router
    ├── UnxswapRouter.sol           # Uniswap V2 router
    ├── UnxswapV3Router.sol         # Uniswap V3 router
    ├── TokenApprove.sol            # Token approval helper
    ├── TokenApproveProxy.sol       # Approval proxy
    ├── adapter/                    # Protocol adapters
    │   ├── UniAdapter.sol          # Uniswap adapters
    │   ├── CurveAdapter.sol        # Curve adapters
    │   ├── AaveV2Adapter.sol       # Lending protocol adapters
    │   └── ...                     # Many other protocol adapters
    ├── interfaces/                 # Contract interfaces
    ├── libraries/                  # Utility libraries
    └── utils/                      # Utility contracts
```

## Core Features

- **Multi-Protocol Routing**: Aggregate liquidity across Uniswap V2/V3, Curve, and other major DEXs
- **Split Trading**: Execute trades across multiple liquidity sources for optimal pricing
- **Gas Optimization**: Efficient routing algorithms to minimize transaction costs
- **Extensible Architecture**: Modular adapter system for easy protocol integration

## Installation

```bash
npm install
npx hardhat compile
npx hardhat test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

We welcome contributions! Please see our [Discord community](https://discord.gg/okxdexapi) for technical discussions and support.

### Ways to Contribute

1. **Join Community Discussions** - Help other developers in our Discord
2. **Open Issues** - Report bugs or suggest features
3. **Submit Pull Requests** - Contribute code improvements

### Pull Request Guidelines

- Discuss non-trivial changes in an issue first
- Include tests for new functionality  
- Update documentation as needed
- Add a changelog entry describing your changes

## Security

For security concerns, please see our [bug bounty program](https://hackerone.com/okg/policy_scopes?type=team) or contact the team directly.

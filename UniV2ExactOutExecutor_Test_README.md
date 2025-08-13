# UniV2ExactOutExecutor Fork Test

This test file (`src/tests/UniV2ExactOutExecutorForkTest.t.sol`) provides comprehensive fork tests for the `UniV2ExactOutExecutor` contract, specifically testing the integration with `DexRouter.executeWithBaseRequest` function.

## Overview

The test suite covers:
- **WETH to USDC swaps** - Testing exact output swaps using Uniswap V2 pools
- **USDC to DAI swaps** - Multi-hop swaps through WETH
- **ETH to USDC swaps** - Native ETH input with automatic WETH wrapping
- **USDC to ETH swaps** - Output to native ETH with automatic WETH unwrapping
- **Preview function testing** - Validating amount calculations
- **Error handling** - Testing insufficient max amount scenarios

## Key Features

### Fork Testing Setup
- Forks Ethereum mainnet at block 18,500,000
- Uses real Uniswap V2 factory and pair contracts
- Interacts with actual token contracts (WETH, USDC, DAI, USDT)

### Contract Integration
- Deploys `UniV2ExactOutExecutor` contract
- Integrates with existing `DexRouter` contract
- Uses real `TokenApprove` and `TokenApproveProxy` contracts from mainnet

### Test Cases

#### 1. `testExecuteWithBaseRequest_WETH_to_USDC()`
Tests a simple WETH → USDC swap:
- Input: Max 1 WETH
- Output: Exactly 1000 USDC
- Uses WETH/USDC Uniswap V2 pair

#### 2. `testExecuteWithBaseRequest_USDC_to_DAI()`
Tests a multi-hop USDC → WETH → DAI swap:
- Input: Max 1100 USDC
- Output: Exactly 1000 DAI
- Routes through two Uniswap V2 pairs

#### 3. `testExecuteWithBaseRequest_ETH_to_USDC()`
Tests native ETH input:
- Input: Max 1 ETH (sent as msg.value)
- Output: Exactly 2000 USDC
- Automatically wraps ETH to WETH

#### 4. `testExecuteWithBaseRequest_USDC_to_ETH()`
Tests native ETH output:
- Input: Max 2000 USDC
- Output: Exactly 0.5 ETH
- Automatically unwraps WETH to ETH

#### 5. `testPreviewFunction()`
Tests the preview calculation:
- Calculates required WETH for 1000 USDC output
- Validates the preview function accuracy

#### 6. `testFailInsufficientMaxAmount()`
Tests error handling:
- Sets very low max amount (0.01 WETH)
- Expects revert with "consumeAmount > maxConsumeAmount"

## Pool Data Encoding

The test uses the `_buildPool` function to encode Uniswap V2 pool data:
- **Address**: Pool contract address (20 bytes)
- **Numerator**: Fee numerator (997000000 for 0.3% fee)
- **Flags**: Direction and WETH unwrap flags
  - Bit 255: Reverse flag (token order)
  - Bit 254: WETH unwrap flag (for ETH output)

## Prerequisites

To run these tests, you need:

1. **Foundry installed**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Ethereum RPC endpoint** configured in `foundry.toml`:
   ```toml
   [rpc_endpoints]
   eth = "https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
   ```

## Running the Tests

```bash
# Run all tests in the contract
forge test --match-contract UniV2ExactOutExecutorForkTest -vvv

# Run a specific test
forge test --match-test testExecuteWithBaseRequest_WETH_to_USDC -vvv

# Run with more verbose output
forge test --match-contract UniV2ExactOutExecutorForkTest -vvvv

# Run tests with gas reporting
forge test --match-contract UniV2ExactOutExecutorForkTest --gas-report
```

## Expected Output

Each test will show:
- Initial token balances
- Final token balances after swap
- Amount consumed from input token
- Amount received of output token
- Return amount from the executor

Example output:
```
Initial WETH balance: 50000000000000000000
Initial USDC balance: 100000000000
Final WETH balance: 49123456789012345678
Final USDC balance: 101000000000
Return amount: 1000000000
WETH consumed: 876543210987654322
USDC received: 1000000000
```

## Important Notes

1. **Real Mainnet State**: Tests use actual Ethereum mainnet state, so results depend on current pool reserves and prices.

2. **Gas Costs**: Fork tests include realistic gas costs and may fail if gas limits are too low.

3. **Slippage**: Tests include 1% slippage tolerance in `minReturnAmount` calculations.

4. **Block Number**: Tests fork at block 18,500,000. You may need to update this to a more recent block for current testing.

5. **Token Approvals**: Tests properly handle token approvals through the `TokenApprove` contract system.

## Troubleshooting

### Common Issues:

1. **"Pair not found"**: Update the fork block number to ensure Uniswap V2 pairs exist.

2. **"Insufficient liquidity"**: Reduce swap amounts or check pool reserves at the fork block.

3. **"consumeAmount > maxConsumeAmount"**: Increase `maxConsumeAmount` or reduce `amountOut`.

4. **RPC errors**: Ensure your Ethereum RPC endpoint is working and has sufficient rate limits.

### Debugging:

Add more console logs to debug issues:
```solidity
console2.log("Pool address:", poolAddress);
console2.log("Token0:", IUniswapV2Pair(poolAddress).token0());
console2.log("Token1:", IUniswapV2Pair(poolAddress).token1());
```

## Contract Addresses Used

- **WETH**: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
- **USDC**: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
- **DAI**: `0x6B175474E89094C44Da98b954EedeAC495271d0F`
- **USDT**: `0xdAC17F958D2ee523a2206206994597C13D831ec7`
- **Uniswap V2 Factory**: `0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f`
- **TokenApprove**: `0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f`
- **TokenApproveProxy**: `0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58`
- **WNativeRelayer**: `0x5703B683c7F928b721CA95Da988d73a3299d4757`

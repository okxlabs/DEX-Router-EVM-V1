# SOR SmartContract

# First Step

``` npm install ```

Fill your test private key into the .env file at the root of your project

# Second Step

``` npx hardhat compile ```

# Deploy

The UnxswapRouter contract code is hardcoded to replace the address in the current chain before deployment

```
uint256 public constant _WETH = 0x0000000000000000000000008f8526dbfd6e38e3d8307702ca8469bae6c56c15;
uint256 public constant _APPROVE_PROXY_32 = 0x000000000000000000000000E9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF;
uint256 public constant _WNATIVE_RELAY_32 = 0x000000000000000000000000d99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98;
```
# SOR SmartContract

# First Step

``` npm install ```

Fill your test private key into the .env file at the root of your project

# Second Step

``` npx hardhat compile ```

# Deploy

The UnxswapRouter contract code is hardcoded to replace the address in the current chain before deployment

```
/// WETH address is network-specific and needs to be changed before deployment.
/// It can not be moved to immutable as immutables are not supported in assembly
// ETH:     C02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
// BSC:     bb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
// OEC:     8f8526dbfd6e38e3d8307702ca8469bae6c56c15
// LOCAL:   5FbDB2315678afecb367f032d93F642f64180aa3
// POLYGON: 0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
// AVAX:    B31f66AA3C1e785363F0875A1B74E27b85FD66c7
uint256 public constant _WETH = 0x0000000000000000000000000d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
// ETH:     70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58
// BSC:     d99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98
// OEC:     E9BBD6eC0c9Ca71d3DcCD1282EE9de4F811E50aF
// LOCAL:   e7f1725E7734CE288F8367e1Bb143E90bb3F0512
// POLYGON: 40aA958dd87FC8305b97f2BA922CDdCa374bcD7f
// AVAX:    70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58
uint256 public constant _APPROVE_PROXY_32 = 0x00000000000000000000000040aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
// ETH:     5703B683c7F928b721CA95Da988d73a3299d4757
// BSC:     0B5f474ad0e3f7ef629BD10dbf9e4a8Fd60d9A48
// OEC:     d99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98
// LOCAL:   D49a0e9A4CD5979aE36840f542D2d7f02C4817Be
// POLYGON: f332761c673b59B21fF6dfa8adA44d78c12dEF09
// AVAX:    3B86917369B83a6892f553609F3c2F439C184e31
uint256 public constant _WNATIVE_RELAY_32 = 0x000000000000000000000000f332761c673b59B21fF6dfa8adA44d78c12dEF09;
```
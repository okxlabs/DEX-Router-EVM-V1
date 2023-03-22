const { ethers } = require('hardhat');

// There are two code snippets that need to be replaced
// 1. contracts/8/draft-EIP712Upgradable.sol
// 2. contracts/8/PMMRouter.sol
async function main() {
  PmmConstantsTool = await ethers.getContractFactory("PmmConstantsTool");
  pmmConstantsTool = await PmmConstantsTool.deploy();
  
  const _NAME = "METAX MARKET MAKER";
  const _VERSION = "1.0";

  // Please replace with the current chain id and dexRouter contract address
  const _CHAIN_ID = 1;
  const _DEX_ROUTER_ADDR = "0x3b3ae790Df4F312e745D270119c6052904FB6790";

  const result = await pmmConstantsTool.calPMMConstants(_NAME, _VERSION, _CHAIN_ID, _DEX_ROUTER_ADDR);
  console.log(result);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
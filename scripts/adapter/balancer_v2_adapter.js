const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
  const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";
  const WETH = tokenConfig.tokens.WETH.baseTokenAddress;

  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault, WETH);
  await balancerV2Adapter.deployed();

  console.log(`balancerV2Adapter deployed: ${balancerV2Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

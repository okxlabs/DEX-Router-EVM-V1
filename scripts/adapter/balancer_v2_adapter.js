const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
  const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault, deployed.base.wNativeToken);
  await balancerV2Adapter.deployed();

  console.log(`balancerV2Adapter deployed: ${balancerV2Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

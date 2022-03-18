const { ethers } = require("hardhat");

async function main() {
  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy();
  await balancerV2Adapter.deployed();

  console.log(`balancerV2Adapter deployed: ${balancerV2Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

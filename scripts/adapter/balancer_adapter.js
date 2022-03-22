const { ethers } = require("hardhat");

async function main() {
  BalancerAdapter = await ethers.getContractFactory("BalancerAdapter");
  balancerAdapter = await BalancerAdapter.deploy();
  await balancerAdapter.deployed();

  console.log(`balancerAdapter deployed: ${balancerAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

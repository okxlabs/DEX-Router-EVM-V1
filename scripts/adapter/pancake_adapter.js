const { ethers, upgrades } = require("hardhat");

async function main() {
  PancakeAdapter = await ethers.getContractFactory("PancakeAdapter");
  pancakeAdapter = await upgrades.deployProxy(PancakeAdapter);
  await pancakeAdapter.deployed();

  console.log(`pancakeAdapter deployed: ${pancakeAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

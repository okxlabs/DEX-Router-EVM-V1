const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  DexRouter = await ethers.getContractFactory("DexRouter");
  dexRouter = await upgrades.deployProxy(
    DexRouter, []
  );
  await dexRouter.deployed();

  console.log("dexRouter: " + dexRouter.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

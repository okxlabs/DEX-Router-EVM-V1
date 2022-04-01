const { ethers } = require("hardhat");
const deployed = require('../deployed');

async function main() {

  console.log(deployed);

  DexRouter = await ethers.getContractFactory("DexRouter");
  r = await upgrades.upgradeProxy(
    deployed.base.dexRouter,
    DexRouter
  );

  console.log("update finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

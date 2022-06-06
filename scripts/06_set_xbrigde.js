const { assert } = require("chai");
const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  )
  await dexRouter.setXBridge(deployed.xbridge);

  console.log("set XBridge finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

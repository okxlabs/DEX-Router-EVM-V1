const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  )
  await dexRouter.initializePMMRouter(
    "0x000000000000000000000000e35a050360579253881e449d67640d54a9ad8277"
  );

  console.log("set fee receiver finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );
  await dexRouter.setPriorityAddress(
    deployed.base.xbridge,
    true
  );
  await dexRouter.setPriorityAddress(
    deployed.base.limitOrder,
    true
  );
  console.log("set priority address finish");

  await dexRouter.setProtocolAdmin(deployed.base.protocolAdmin);
  console.log("set ProtocolAdmin finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

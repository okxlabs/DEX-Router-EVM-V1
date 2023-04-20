const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");

async function main() {
  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );

  console.log("######### START CHECK ProtocolAdmin ##########");
  if (ethers.utils.isAddress(deployed.base.dexRouter)) {
    assert.equal(await dexRouter.tmpAdmin(), deployed.base.protocolAdmin);
    assert.equal(await dexRouter.admin(), deployed.base.protocolAdmin);
  }
  console.log("######### END CHECK ProtocolAdmin ##########\n");

  console.log("######### START CHECK PriorityAddresses:xbridge ##########");
  if (ethers.utils.isAddress(deployed.base.dexRouter)) {
    assert.equal(await dexRouter.priorityAddresses(deployed.base.xbridge), true);
  }
  console.log("######### END CHECK PriorityAddresses:xbridge ##########\n");

  console.log("######### START CHECK PriorityAddresses:limitOrder ##########");
  if (ethers.utils.isAddress(deployed.base.dexRouter)) {
    assert.equal(await dexRouter.priorityAddresses(deployed.base.limitOrder), true);
  }
  console.log("######### END CHECK PriorityAddresses:limitOrder ##########\n");

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");

async function main() {
  //console.log(deployed);

  console.log("##set tokenApproveProxy owner begin");

  const newOwner = "0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87";
  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  );

  const owner = await tokenApproveProxy.owner();
  console.log("before owner:", owner);

  assert.equal(owner, newOwner);

  //await tokenApproveProxy.transferOwnership(newOwner);
  console.log("##set tokenApproveProxy owner finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");

async function main() {
  //console.log(deployed);

  console.log("##set tokenApproveProxy owner begin");

  const newOwner = "0xE1C7Db7575BABF0d3369835678ec9b7F15c0886B";
  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  );

  const owner = await tokenApproveProxy.owner();
  console.log("before owner:", owner);

  assert.equal(owner, newOwner);

  // await tokenApproveProxy.transferOwnership(newOwner);
  console.log("##set tokenApproveProxy owner finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

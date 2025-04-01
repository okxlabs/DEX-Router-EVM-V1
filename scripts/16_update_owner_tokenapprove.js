const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");

async function main() {
  console.log("##set tokenApprove owner begin");

  const newOwner = "0xE1C7Db7575BABF0d3369835678ec9b7F15c0886B";
  const tokenApprove = await ethers.getContractAt(
    "TokenApprove",
    deployed.base.tokenApprove
  );

  const owner = await tokenApprove.owner();
  console.log("before owner:", owner);

  assert.equal(owner, newOwner);

  //await tokenApprove.transferOwnership(newOwner);
  console.log("##set tokenApprove owner finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

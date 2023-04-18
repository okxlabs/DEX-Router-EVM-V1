const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");

async function main() {
  console.log("##set tokenApprove owner begin");

  const newOwner = "0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87";
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

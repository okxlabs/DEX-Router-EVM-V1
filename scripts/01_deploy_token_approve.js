const { ethers } = require("hardhat");

async function main() {
  TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
  tokenApproveProxy = await TokenApproveProxy.deploy();
  await tokenApproveProxy.deployed();
  await tokenApproveProxy.initialize();
  console.log("tokenApproveProxy: " + tokenApproveProxy.address);

  TokenApprove = await ethers.getContractFactory("TokenApprove");
  tokenApprove = await TokenApprove.deploy();
  await tokenApprove.deployed();
  await tokenApprove.initialize(tokenApproveProxy.address);
  console.log("tokenApprove: " + tokenApprove.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  tokenApprove = await ethers.getContractAt(
    "TokenApprove",
    deployed.tokenApprove
  )

  tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.tokenApproveProxy
  )

  await tokenApprove.init(owner.address, tokenApproveProxy);
  console.log("tokenApprove init");

  DexRoute = await ethers.getContractFactory("DexRoute");
  dexRoute = await upgrades.deployProxy(DexRoute, [deployed.WBNB, deployed.tokenApproveProxy]);
  await dexRoute.deployed();
  await dexRoute.setTokenAprrove(tokenApprove.address);
  console.log("dexRoute: " + dexRoute.address);

  await tokenApproveProxy.addProxy(deployed.dexRoute);
  console.log("tokenApproveProxy add dexProxy")
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

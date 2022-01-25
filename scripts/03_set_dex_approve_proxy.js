const { ethers } = require("hardhat");
const address = require("./deployed");

async function main() {
  console.log(address.base.dexRoute)
  const dexRouteProxy = await ethers.getContractAt(
    "DexRouteProxy",
    deployed.dexRoute
  );

  await dexRouteProxy.setApproveProxy(address.tokenApprove);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

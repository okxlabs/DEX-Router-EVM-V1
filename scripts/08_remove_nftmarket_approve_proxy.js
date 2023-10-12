const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  )

  const nftmarket = deployed.base.nftmarket;
  let isProxy = await tokenApproveProxy.allowedApprove(nftmarket);
  if (isProxy) {
    let result = await tokenApproveProxy.removeProxy(nftmarket);
    console.log(`## Remove nftmarket proxy:[%s] txHash:[%s]`, nftmarket, result.hash);
  } else {
    console.log(`## Skip remove nftmarket proxy:[%s]`, nftmarket);
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

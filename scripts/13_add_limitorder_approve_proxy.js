const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  )
  const limitOrder = deployed.base.limitOrderV2;
  let isProxy = await tokenApproveProxy.allowedApprove(limitOrder);
  if (!isProxy) {
    let result = await tokenApproveProxy.addProxy(limitOrder);
    console.log(`## Add proxy:[%s] txHash:[%s]`, limitOrder, result.hash);
  } else {
    console.log(`## Skip add proxy:[%s]`, limitOrder);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  )

  const xbridge = deployed.base.xbridge;
  let isProxy = await tokenApproveProxy.allowedApprove(xbridge);
  if (!isProxy) {
    let result = await tokenApproveProxy.addProxy(xbridge);
    console.log(`## Add proxy:[%s] txHash:[%s]`, xbridge, result.hash);
  } else {
    console.log(`## Skip add proxy:[%s]`, xbridge);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

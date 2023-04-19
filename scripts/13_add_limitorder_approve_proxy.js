const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  )

  const result = await tokenApproveProxy.addProxy(deployed.base.limitOrder);
  console.log(`tokenApproveProxy add proxy ${deployed.base.limitOrder}`);
  console.log(`txHash:`, result.hash);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

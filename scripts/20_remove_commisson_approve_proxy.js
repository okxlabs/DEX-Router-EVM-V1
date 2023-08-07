const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  )

  const commisson = deployed.base.commisson;
  let isProxy = await tokenApproveProxy.allowedApprove(commisson);
  if(isProxy){
    let result = await tokenApproveProxy.removeProxy(commisson);
    console.log(`## Remove proxy:[%s] txHash:[%s]`, commisson, result.hash);
  }else{
    console.log(`## Skip remove proxy:[%s]`, commisson);
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

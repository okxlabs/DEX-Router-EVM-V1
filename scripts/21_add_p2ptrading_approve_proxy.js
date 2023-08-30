const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  )

  const p2pTrading = deployed.base.p2pTrading;
  let isProxy = await tokenApproveProxy.allowedApprove(p2pTrading);
  if(!isProxy){
    let result = await tokenApproveProxy.addProxy(p2pTrading);
    console.log(`## Add proxy:[%s] txHash:[%s]`, p2pTrading, result.hash);
  }else{
    console.log(`## Skip add proxy:[%s]`, p2pTrading);
  }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

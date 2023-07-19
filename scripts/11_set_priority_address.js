const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );
  
  const xbridge = deployed.base.xbridge;
  const limitOrder = deployed.base.limitOrder;
  const commisson = deployed.base.commisson;
  
  let isPriority = await dexRouter.priorityAddresses(xbridge);
  if(!isPriority){
    let result = await dexRouter.setPriorityAddress(xbridge, true);
    console.log(`## Add xbridge:[%s] priority txHash:[%s]`, xbridge, result.hash);
  }else{
    console.log(`## Skip add xbridge:[%s] priority`, xbridge);
  }

  isPriority = await dexRouter.priorityAddresses(limitOrder);
  if(!isPriority){
    let result = await dexRouter.setPriorityAddress(limitOrder, true);
    console.log(`## Add limitOrder:[%s] priority txHash:[%s]`, limitOrder, result.hash);
  }else{
    console.log(`## Skip add limitOrder:[%s] priority`, limitOrder);
  }

  isPriority = await dexRouter.priorityAddresses(commisson);
  if(!isPriority){
    let result = await dexRouter.setPriorityAddress(commisson, true);
    console.log(`## Add commisson:[%s] priority txHash:[%s]`, commisson, result.hash);
  }else{
    console.log(`## Skip add commisson:[%s] priority`, commisson);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

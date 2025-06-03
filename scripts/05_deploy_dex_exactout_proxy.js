const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed.base);

  DexRouter = await ethers.getContractFactory("DexRouterExactOut");
  dexRouter = await upgrades.deployProxy(
    DexRouter, []
  );
  await dexRouter.deployed();

  console.log("dexRouterExactOut: " + dexRouter.address);
  // let dexRouter = {address: deployed.base.preDexRouterExactOut};

  const proxy = await ethers.getContractAt("TransparentUpgradeableProxy", dexRouter.address);
  const implAddress = await upgrades.erc1967.getImplementationAddress(proxy.address);
  console.log("Implementation address: ", implAddress);

  const dexRouterImpl = await ethers.getContractAt("DexRouterExactOut", implAddress)
  let tx = await dexRouterImpl.initialize();
  console.log("dexRouterExactOut initialized: ", tx);

  console.log("--------------------------------");
  await new Promise(resolve => setTimeout(resolve, 12000));
  let implOwner = await dexRouterImpl.owner();
  console.log("implOwner: ", implOwner);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

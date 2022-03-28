const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed.base);

  WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
  wNativeRelayer = await WNativeRelayer.deploy();
  await wNativeRelayer.deployed();
  await wNativeRelayer.initialize(deployed.base.wNativeToken);
  console.log("wNativeRelayer " + wNativeRelayer.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
  SmoothyV1Adapter = await ethers.getContractFactory("SmoothyV1Adapter");
  smoothyV1Adapter = await SmoothyV1Adapter.deploy();
  await smoothyV1Adapter.deployed();

  console.log(`smoothyV1Adapter deployed: ${smoothyV1Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

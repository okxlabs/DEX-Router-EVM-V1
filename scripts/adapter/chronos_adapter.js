const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("arb");

async function main() {

  let chronosAdapter = await ethers.getContractFactory("ChronosAdapter");
  let ChronosAdapter = await chronosAdapter.deploy();
  await ChronosAdapter.deployed();

  console.log(`ChronosAdapter deployed: ${ChronosAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

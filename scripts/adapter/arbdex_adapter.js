const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("arb");

async function main() {

  let arbDexAdapter = await ethers.getContractFactory("ArbDexAdapter");
  let ArbDexAdapter = await arbDexAdapter.deploy();
  await ArbDexAdapter.deployed();

  console.log(`ArbDexAdapter deployed: ${ArbDexAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

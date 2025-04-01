const { ethers } = require("hardhat");

async function main() {
  let MimoV2Adapter = await ethers.getContractFactory("UniAdapter");
  let mimoV2Adapter = await MimoV2Adapter.deploy();
  await mimoV2Adapter.deployed();

  console.log(`mimoV2Adapter deployed: ${mimoV2Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

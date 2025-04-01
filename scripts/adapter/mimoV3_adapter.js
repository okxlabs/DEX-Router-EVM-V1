const { ethers } = require("hardhat");

async function main() {
  let MimoV3Adapter = await ethers.getContractFactory("UniV3Adapter");
  let mimoV3Adapter = await MimoV3Adapter.deploy("0xA00744882684C3e4747faEFD68D283eA44099D03");
  await mimoV3Adapter.deployed();

  console.log(`MimoV3Adapter deployed: ${mimoV3Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
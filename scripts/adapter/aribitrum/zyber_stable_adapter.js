const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    ZyberStableAdapter = await ethers.getContractFactory("ZyberStableAdapter");
    ZyberStableAdapter = await ZyberStableAdapter.deploy();
    await ZyberStableAdapter.deployed();

    console.log(`ZyberStableAdapter deployed: ${ZyberStableAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

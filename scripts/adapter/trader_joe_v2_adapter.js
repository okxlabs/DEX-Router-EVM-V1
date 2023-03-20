const { ethers } = require("hardhat");

async function main() {
    TraderJoeV2Adapter = await ethers.getContractFactory("TraderJoeV2Adapter");
    TraderJoeV2Adapter = await TraderJoeV2Adapter.deploy();
    await TraderJoeV2Adapter.deployed();

    console.log(`TraderJoeV2Adapter deployed: ${TraderJoeV2Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

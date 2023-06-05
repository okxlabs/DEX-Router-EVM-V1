const { ethers } = require("hardhat");

async function main() {
    TraderJoeV2P1Adapter = await ethers.getContractFactory("TraderJoeV2P1Adapter");
    TraderJoeV2P1Adapter = await TraderJoeV2P1Adapter.deploy();
    await TraderJoeV2P1Adapter.deployed();

    console.log(`TraderJoeV2P1Adapter deployed: ${TraderJoeV2P1Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

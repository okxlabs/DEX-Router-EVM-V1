const { ethers } = require("hardhat");

async function main() {
    CameplotAdapter = await ethers.getContractFactory("CameplotAdapter");
    CameplotAdapter = await CameplotAdapter.deploy();
    await CameplotAdapter.deployed();

    console.log(`CameplotAdapter deployed: ${CameplotAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

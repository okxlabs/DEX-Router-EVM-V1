const { ethers } = require("hardhat");

async function main() {
  CurveAdapter = await ethers.getContractFactory("CurveAdapter");
  curveAdapter = await CurveAdapter.deploy();
  await curveAdapter.deployed();

  console.log(`curveAdapter deployed: ${curveAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");

async function main() {
  CurveAdapter = await ethers.getContractFactory("CurveAdapter");
  curveAdapter = await CurveAdapter.deploy();
  await curveAdapter.deployed();
  // CurveAdapterCopy
  CurveAdapterCopy = await ethers.getContractFactory("CurveAdapterCopy");
  CurveAdapterCopy = await CurveAdapterCopy.deploy();
  await CurveAdapterCopy.deployed();

  console.log(`curveAdapter deployed: ${curveAdapter.address}`);
  console.log(`CurveAdapterCopy deployed: ${CurveAdapterCopy.address}`);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

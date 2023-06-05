const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

  let xSigmaAdapter = await ethers.getContractFactory("XSigmaAdapter");
  let XSigmaAdapter = await xSigmaAdapter.deploy();
  await XSigmaAdapter.deployed();

  console.log(`CurveAdapter deployed: ${XSigmaAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

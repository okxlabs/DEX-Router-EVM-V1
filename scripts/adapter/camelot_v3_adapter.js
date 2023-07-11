const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("arb");

async function main() {
  let camelotV3Adapter = await ethers.getContractFactory("CamelotV3Adapter");
  let CamelotV3Adapter = await camelotV3Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
  await CamelotV3Adapter.deployed();

  console.log(`CamelotV3Adapter deployed: ${CamelotV3Adapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

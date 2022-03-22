const { ethers } = require("hardhat");

async function main() {
  KyberAdapter = await ethers.getContractFactory("KyberAdapter");
  kyberAdapter = await KyberAdapter.deploy();
  await kyberAdapter.deployed();

  console.log(`kyberAdapter deployed: ${kyberAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

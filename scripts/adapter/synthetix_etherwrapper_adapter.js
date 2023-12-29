const { ethers } = require("hardhat");

async function main() {
    SynthetixEtherWrapperAdapter = await ethers.getContractFactory("SynthetixEtherWrapperAdapter");
    synthetixEtherWrapperAdapter = await SynthetixEtherWrapperAdapter.deploy();
    await synthetixEtherWrapperAdapter.deployed();

    console.log(`synthetixEtherWrapperAdapter deployed: ${synthetixEtherWrapperAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

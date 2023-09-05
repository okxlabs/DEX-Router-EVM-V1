const { ethers } = require("hardhat");

async function main() {
    WrappedSynthetixAdapter = await ethers.getContractFactory("WrappedSynthetixAdapter");
    wrappedSynthetixAdapter = await WrappedSynthetixAdapter.deploy();
    await wrappedSynthetixAdapter.deployed();

    console.log(`wrappedSynthetixAdapter deployed: ${wrappedSynthetixAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

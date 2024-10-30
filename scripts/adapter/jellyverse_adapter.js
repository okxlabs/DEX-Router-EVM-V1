const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
  const jellyverseVault = "0xFB43069f6d0473B85686a85F4Ce4Fc1FD8F00875";

  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  jellyverseAdapter = await BalancerV2Adapter.deploy(jellyverseVault, deployed.base.wNativeToken);
  await jellyverseAdapter.deployed();

  console.log(`jellyverseAdapter deployed: ${jellyverseAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

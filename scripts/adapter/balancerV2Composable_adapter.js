const { ethers } = require("hardhat");
const deployed = require("../deployed");

const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";
const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

async function main() {
  BalancerV2ComposableAdapter = await ethers.getContractFactory("BalancerV2ComposableAdapter");
  BalancerV2ComposableAdapter = await BalancerV2ComposableAdapter.deploy(balancerVault,WETHAddress );
  await BalancerV2ComposableAdapter.deployed();
  
  console.log(`BalancerV2ComposableAdapter deployed: ${BalancerV2ComposableAdapter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

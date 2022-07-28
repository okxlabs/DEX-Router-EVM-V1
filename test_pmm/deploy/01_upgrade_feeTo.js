const { ethers, upgrades } = require("hardhat");
require("../../scripts/tools");
const deployed = require('../../scripts/deployed');
const pmm_params = require("../pmm/pmm_params");

console.log(deployed);
console.log(pmm_params);

async function main() {
    marketMaker = await ethers.getContractAt(
        "MarketMaker",
        deployed.base.marketMaker
    );

    console.log("marketMaker: ", marketMaker.address);

    console.log("old feeTo", await marketMaker.feeTo());
    console.log("old feeRate", await marketMaker.feeRate());

    let tx = await marketMaker.feeConfig(pmm_params.feeTo, pmm_params.feeRate);
    let receipt = await tx.wait();
    console.log("receipt",receipt);
    
    console.log("new feeTo", await marketMaker.feeTo());
    console.log("new feeRate", await marketMaker.feeRate());
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
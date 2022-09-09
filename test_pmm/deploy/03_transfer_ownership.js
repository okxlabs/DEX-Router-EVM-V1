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

    proxyAdmin = await ethers.getContractAt(
        "MarketMaker",
        deployed.base.marketMakerProxyAdmin
    );

    console.log("old cancelerGuardian", await marketMaker.cancelerGuardian());
    console.log("old owner", await marketMaker.owner());
    console.log("old proxyAdminOwner", await proxyAdmin.owner());

    await marketMaker.setCancelerGuardian(pmm_params.cancelerGuardian);
    await marketMaker.transferOwnership(pmm_params.tradeOwner);
    await upgrades.admin.transferProxyAdminOwnership(pmm_params.tradeOwner);

    console.log("new cancelerGuardian", await marketMaker.cancelerGuardian());
    console.log("new owner", await marketMaker.owner());
    console.log("new proxyAdminOwner", await proxyAdmin.owner());

}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
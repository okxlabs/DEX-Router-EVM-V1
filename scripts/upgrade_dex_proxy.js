const { ethers } = require("hardhat");
const base = require("deployed")

async function main() {

  console.log(base);

  DexRouteProxy = await ethers.getContractFactory("DexRoute");
  r = await upgrades.upgradeProxy(
    base.dexRoute,
    DexRouteProxy
  );

  console.log("update finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const deployed = require('../deployed');

async function main() {
  console.log(deployed);

  const instance = await upgrades.admin.getInstance();
  const proxyAdminAddress = await instance.getProxyAdmin(deployed.base.dexRouter);
  console.log("proxyAdmin:", proxyAdminAddress);

  proxyAdmin = await ethers.getContractAt(
    "ProxyAdmin",
    proxyAdminAddress
  );

  //升级逻辑合约
  const newLogicContract = "0xe1762dE0432D213a33e7127a359bD0a2abB8CF31"; //flare new logic

  console.log("upgrade dexRouter to:", newLogicContract);
  await proxyAdmin.upgrade(deployed.base.dexRouter, newLogicContract);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

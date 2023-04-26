const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { upgrades } = require('hardhat');

async function main() {
  console.log("##CHANGE OWNER BEGIN");

  const newOwner = "0xE1C7Db7575BABF0d3369835678ec9b7F15c0886B"; //资管账号
  //const oldAdmin = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6"; //旧admin
  const newAdmin = "0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87"; //新admin
  const newLogicContract = "0x1b5d39419C268b76Db06DE49e38B010fbFB5e226";

  // ProxyAdmin
  //ETHW: 0x91597356448f771363Ae3C3d7B87C8D6f2f63B25
  //Fantom: 0x5703B683c7F928b721CA95Da988d73a3299d4757
  //Cronos: 0x5703B683c7F928b721CA95Da988d73a3299d4757

  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );
  console.log("dexRouter:", deployed.base.dexRouter);
  console.log("dexRouter.owner:", await dexRouter.owner());
  console.log("dexRouter.tmpAdmin:", await dexRouter.tmpAdmin());
  console.log("dexRouter.admin:", await dexRouter.admin());
  console.log("\n");

  const instance = await upgrades.admin.getInstance();
  const proxyAdminAddress = await instance.getProxyAdmin(deployed.base.dexRouter);
  console.log("proxyAdmin:", proxyAdminAddress);

  proxyAdmin = await ethers.getContractAt(
    "ProxyAdmin",
    proxyAdminAddress
  );

  console.log("proxyAdmin.owner:", await proxyAdmin.owner());
  console.log("proxyAdmin.logicContract:", await proxyAdmin.getProxyImplementation(deployed.base.dexRouter));
  console.log("owner nonce:", await ethers.provider.getTransactionCount(newAdmin));


  //转移owner
  //await dexRouter.transferOwnership(newAdmin);
  //await proxyAdmin.transferOwnership(newAdmin);

  //升级逻辑合约
  //await proxyAdmin.upgrade(deployed.base.dexRouter, newLogicContract);

  console.log("##CHANGE OWNER FINISH\n");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

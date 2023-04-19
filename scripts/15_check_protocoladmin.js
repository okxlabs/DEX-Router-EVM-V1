const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");

async function main() {
  console.log("##check ProtocolAdmin begin");

  const oldAdmin = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
  const newAdmin = "0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87";

  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );

  const tmpAdmin = await dexRouter.tmpAdmin();
  const admin = await dexRouter.admin();

  console.log("tmpAdmin:", tmpAdmin);
  console.log("admin:", admin);

  assert.equal(await dexRouter.tmpAdmin(), oldAdmin);
  assert.equal(await dexRouter.admin(), newAdmin);

  console.log("##check ProtocolAdmin finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

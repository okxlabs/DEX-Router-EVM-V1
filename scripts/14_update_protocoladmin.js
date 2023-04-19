const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log("##set ProtocolAdmin begin");
  const newAdmin = "0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87";
  const dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );

  const tmpAdmin = await dexRouter.tmpAdmin();
  const admin = await dexRouter.admin();
  console.log("before tmpAdmin:", tmpAdmin);
  console.log("before admin:", admin);

  await dexRouter.setProtocolAdmin(newAdmin);
  console.log("##set ProtocolAdmin finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

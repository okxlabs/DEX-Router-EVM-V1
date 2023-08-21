const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  // const dexRouter = await ethers.getContractAt(
  //   "DexRouter",
  //   deployed.base.dexRouter
  // )

  const tokenApprove = await ethers.getContractAt(
    "TokenApprove",
    deployed.base.tokenApprove
  )

  console.log(await tokenApprove.tokenApproveProxy());
  // console.log(await dexRouter.approveProxy());
  // console.log(await dexRouter.wNativeRelayer());
  // await dexRouter.setApproveProxy("0xd99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98");
  // await dexRouter.setWNativeRelayer("0x0B5f474ad0e3f7ef629BD10dbf9e4a8Fd60d9A48");

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    '0xd99cAE3FAC551f6b6Ba7B9f19bDD316951eeEE98'
  )

  await tokenApproveProxy.addProxy(deployed.base.dexRouter);

  const wNativeRelayer = await ethers.getContractAt(
    "WNativeRelayer",
    "0x0B5f474ad0e3f7ef629BD10dbf9e4a8Fd60d9A48"
  )
  await wNativeRelayer.setCallerOk([deployed.base.dexRouter], [true]);
  console.log("setCallerOk finish");

  console.log("finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

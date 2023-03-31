const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
  console.log(deployed);

  const tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
     "0x03B5ACdA01207824cc7Bc21783Ee5aa2B8d1D2fE"
  )

  await tokenApproveProxy.addProxy("0x993e19336003398c1119D9f125936eC9462233F4");
  console.log(`tokenApproveProxy add proxy 0x993e19336003398c1119D9f125936eC9462233F4`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

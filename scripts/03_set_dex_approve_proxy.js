const { ethers } = require("hardhat");

async function main() {
  const dexRouteProxy = await ethers.getContractAt(
    "DexRouteProxy",
    "0xaCb20732838ce4F71Dc7f78536f827Fc06Af63DB"
  );

  await dexRouteProxy.setApproveProxy('0x683Bbe914e5222BcE638e9EEcA5eC0D4bD3C7A07');

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

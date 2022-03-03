const { ethers } = require("hardhat");

async function main() {
  r = ethers.utils.sha3("function claimTokens(address,address,address,uint256)");
  console.log(r);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

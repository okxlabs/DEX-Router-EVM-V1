const { ethers } = require("hardhat");
require("./tools");

async function execute() {

}

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

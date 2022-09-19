const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    DnyAdapter = await ethers.getContractFactory("DnyFeeAdapter");
    dnyAdapter = await DnyAdapter.deploy();
    await dnyAdapter.deployed();

    console.log(`dny deployed: ${dnyAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
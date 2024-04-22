const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    SolidlyAdapterOnMetis = await ethers.getContractFactory("SolidlyAdapterOnMetis");
    solidlyAdapterOnMetis = await SolidlyAdapterOnMetis.deploy();
    await solidlyAdapterOnMetis.deployed();

    console.log(`SolidlyAdapterOnMetis deployed: ${solidlyAdapterOnMetis.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
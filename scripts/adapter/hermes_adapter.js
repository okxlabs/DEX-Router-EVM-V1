const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

    HermesAdapter = await ethers.getContractFactory("HermesAdapter");
    HermesAdapter = await HermesAdapter.deploy();
    await HermesAdapter.deployed();

    console.log(`HermesAdapter deployed: ${HermesAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

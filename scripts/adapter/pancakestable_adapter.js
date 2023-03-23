const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("bsc");

async function main() {

    PancakestableAdapter = await ethers.getContractFactory("PancakestableAdapter");
    PancakestableAdapter = await PancakestableAdapter.deploy();
    await PancakestableAdapter.deployed();

    console.log(`PancakestableAdapter deployed: ${PancakestableAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

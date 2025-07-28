const { ethers } = require("hardhat");

async function main() {
    FerroAdapter = await ethers.getContractFactory("FerroAdapter");
    ferroAdapter = await FerroAdapter.deploy();
    await ferroAdapter.deployed();

    console.log(`ferroAdapter deployed: ${ferroAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
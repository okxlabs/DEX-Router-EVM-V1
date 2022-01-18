const { ethers, upgrades } = require("hardhat");

async function main() {
    const BiAdapter = await ethers.getContractFactory("BiAdapter");
    const biAdapter = await upgrades.deployProxy(BiAdapter);
    await biAdapter.deployed();

    console.log(`BiAdapter deployed: ${biAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

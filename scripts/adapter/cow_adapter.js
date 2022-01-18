const { ethers, upgrades } = require("hardhat");

async function main() {
    const CowAdapter = await ethers.getContractFactory("CowAdapter");
    const cowAdapter = await upgrades.deployProxy(CowAdapter);
    await cowAdapter.deployed();

    console.log(`CowAdapter deployed: ${cowAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers, upgrades } = require("hardhat");

async function main() {
    UniAdapter = await ethers.getContractFactory("UniAdapter");
    uniAdapter = await upgrades.deployProxy(UniAdapter);
    await uniAdapter.deployed();

    console.log(`uniAdapter deployed: ${uniAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

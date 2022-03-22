const { ethers, upgrades } = require("hardhat");

async function main() {
    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await upgrades.deployProxy(BancorAdapter);
    await bancorAdapter.deployed();

    console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

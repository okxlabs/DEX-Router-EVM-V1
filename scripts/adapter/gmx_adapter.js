const { ethers } = require("hardhat");


async function main() {
    GmxAdapter = await ethers.getContractFactory("GmxAdapter");
    gmxAdapter = await GmxAdapter.deploy();

    await gmxAdapter.deployed();

    console.log(`gmxAdapter deployed: ${gmxAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

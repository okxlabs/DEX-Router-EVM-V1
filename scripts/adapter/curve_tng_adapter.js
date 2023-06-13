const { ethers } = require("hardhat");

async function main() {
    CurveTNGAdapter = await ethers.getContractFactory("CurveTNGAdapter");
    CurveTNGAdapter = await CurveTNGAdapter.deploy();
    await CurveTNGAdapter.deployed();

    console.log(`CurveTNGAdapter deployed: ${CurveTNGAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

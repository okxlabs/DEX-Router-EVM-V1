const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

    SolidlyAdapter = await ethers.getContractFactory("SolidlyAdapter");
    solidlyAdapter = await SolidlyAdapter.deploy();
    await solidlyAdapter.deployed();

    console.log(`solidlyAdapter deployed: ${solidlyAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

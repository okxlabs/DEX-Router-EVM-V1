const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    SolidlyV3Adapter = await ethers.getContractFactory("SolildyV3Adapter");
    solidlyV3Adapter = await SolidlyV3Adapter.deploy();
    await solidlyV3Adapter.deployed();

    console.log(`solidlyV3Adapter deployed: ${solidlyV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    DnyAdapter = await ethers.getContractFactory("NetswapAdapter");
    dnyAdapter = await DnyAdapter.deploy();
    await dnyAdapter.deployed();

    console.log(`NetswapAdapter deployed: ${dnyAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
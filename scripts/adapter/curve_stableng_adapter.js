const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    CurveStableNGAdapter = await ethers.getContractFactory("CurveStableNGAdapter");
    CurveStableNGAdapter = await CurveStableNGAdapter.deploy();
    await CurveStableNGAdapter.deployed();

    console.log(`CurveStableNGAdapter deployed: ${CurveStableNGAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function deployAdapter() {
    MultichainAdapter = await ethers.getContractFactory("MultichainAdapter");
    MultichainAdapter = await MultichainAdapter.deploy();
    await MultichainAdapter.deployed();
    return MultichainAdapter
}

async function main() {
    MultichainAdapter = await deployAdapter();
    console.log(`MultichainAdapter deployed: ${MultichainAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

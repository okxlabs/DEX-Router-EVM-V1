const { ethers } = require("hardhat");


async function main() {
    SynapseAdapter = await ethers.getContractFactory("SynapseAdapter");
    synapseAdapter = await SynapseAdapter.deploy();
    await synapseAdapter.deployed();

    console.log(`synapseAdapter deployed: ${synapseAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

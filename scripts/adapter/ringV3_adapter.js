const { ethers } = require("hardhat");

async function main() {
    RingV3Adapter = await ethers.getContractFactory("RingV3Adapter");
    ringV3Adapter = await RingV3Adapter.deploy("0x4300000000000000000000000000000000000004");
    
    await ringV3Adapter.deployed();

    console.log(`ringV3Adapter deployed: ${ringV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
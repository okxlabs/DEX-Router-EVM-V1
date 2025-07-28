const { ethers } = require("hardhat");

async function main() {
    ZebraV3Adapter = await ethers.getContractFactory("ZebraV3Adapter");
    zebraV3Adapter = await ZebraV3Adapter.deploy("0x5300000000000000000000000000000000000004");
    
    await zebraV3Adapter.deployed();

    console.log(`ZebraV3Adapter deployed: ${zebraV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
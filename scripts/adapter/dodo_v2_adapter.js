const { ethers } = require("hardhat");

async function main() {
    DODOV2Adapter = await ethers.getContractFactory("DODOV2Adapter");
    dodoV2Adapter = await DODOV2Adapter.deploy();
    await dodoV2Adapter.deployed();

    console.log(`dodoV2Adapter deployed: ${dodoV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

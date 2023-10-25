const { ethers } = require("hardhat");

async function main() {
    DODOV3Adapter = await ethers.getContractFactory("DODOV3Adapter");
    dodoV3Adapter = await DODOV3Adapter.deploy();
    await dodoV3Adapter.deployed();

    console.log(`dodoV3Adapter deployed: ${dodoV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

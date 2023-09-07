const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    const wrapNativeToken = deployed.base.wNativeToken;
    const factory = "0xEb6625D65a0553c9dBc64449e56abFe519bd9c9B"
    MaverickAdapter = await ethers.getContractFactory("MaverickAdapter");
    MaverickAdapter = await MaverickAdapter.deploy(factory, wrapNativeToken);
    await MaverickAdapter.deployed();

    console.log(`MaverickAdapter deployed: ${MaverickAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

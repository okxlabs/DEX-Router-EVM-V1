const { ethers } = require("hardhat");


async function main() {
    const WAVAX = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"
    PlatypusAdapter = await ethers.getContractFactory("PlatypusAdapter");
    PlatypusAdapter = await PlatypusAdapter.deploy(WAVAX);
    await PlatypusAdapter.deployed();

    console.log(`PlatypusAdapter deployed: ${PlatypusAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

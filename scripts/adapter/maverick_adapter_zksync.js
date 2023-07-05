const { ethers } = require("hardhat");


async function main() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const factory = "0xEb6625D65a0553c9dBc64449e56abFe519bd9c9B"
    MaverickAdapter = await ethers.getContractFactory("MaverickAdapter");
    MaverickAdapter = await MaverickAdapter.deploy(factory, WETH);
    await MaverickAdapter.deployed();

    console.log(`MaverickAdapter deployed: ${MaverickAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

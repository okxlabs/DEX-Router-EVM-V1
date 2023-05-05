const { ethers } = require("hardhat");


async function main() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    const factory = "0xa5eBD82503c72299073657957F41b9cEA6c0A43A"
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

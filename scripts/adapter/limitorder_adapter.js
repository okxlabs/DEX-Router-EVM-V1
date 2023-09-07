const { ethers } = require("hardhat");

async function main() {
    const aggV5Addr = "0x1111111254EEB25477B68fb85Ed929f73A960582";

    LimitAdapter = await ethers.getContractFactory("LimitOrderAdapter");
    limitAdapter = await LimitAdapter.deploy(aggV5Addr);
    await limitAdapter.deployed();

    console.log(`limitAdapter deployed: ${limitAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

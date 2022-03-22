const { ethers } = require("hardhat");

async function main() {
    UniAdapter = await ethers.getContractFactory("UniAdapter");
    uniAdapter = await UniAdapter.deploy();
    await uniAdapter.deployed();

    console.log(`uniAdapter deployed: ${uniAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

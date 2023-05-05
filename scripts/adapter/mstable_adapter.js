const { ethers } = require("hardhat");


async function main() {
    MstableAdapter = await ethers.getContractFactory("MstableAdapter");
    MstableAdapter = await MstableAdapter.deploy();
    await MstableAdapter.deployed();

    console.log(`mstableAdapter deployed: ${MstableAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

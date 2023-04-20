const { ethers } = require("hardhat");


async function main() {
    SaddleAdapter = await ethers.getContractFactory("SaddleAdapter");
    saddleAdapter = await SaddleAdapter.deploy();
    await saddleAdapter.deployed();

    console.log(`saddleAdapter deployed: ${saddleAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

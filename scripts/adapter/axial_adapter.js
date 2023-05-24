const { ethers } = require("hardhat");


async function main() {
    AxialAdapter = await ethers.getContractFactory("AxialAdapter");
    axialAdapter = await AxialAdapter.deploy();
    await axialAdapter.deployed();

    console.log(`axialAdapter deployed: ${axialAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

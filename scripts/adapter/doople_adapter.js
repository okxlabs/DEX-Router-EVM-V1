const { ethers } = require("hardhat");


async function main() {
    DoppleAdapter = await ethers.getContractFactory("DoppleAdapter");
    doppleAdapter = await DoppleAdapter.deploy();
    await doppleAdapter.deployed();

    console.log(`doppleAdapter deployed: ${doppleAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

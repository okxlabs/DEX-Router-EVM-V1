const { ethers } = require("hardhat");


async function main() {

    ShellAdapter = await ethers.getContractFactory("ShellAdapter");
    ShellAdapter = await ShellAdapter.deploy();
    await ShellAdapter.deployed();


    console.log(`ShellAdapter deployed: ${ShellAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

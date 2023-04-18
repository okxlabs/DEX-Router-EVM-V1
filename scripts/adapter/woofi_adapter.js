
const { ethers } = require("hardhat");

async function getZeroExAdapter() {
    WoofiAdapter = await ethers.getContractFactory("WoofiAdapter");
    WoofiAdapter = await WoofiAdapter.deploy();
    await WoofiAdapter.deployed();    
    return WoofiAdapter
}

async function main() {
    const WoofiAdapter = await getZeroExAdapter()
    console.log("WoofiAdapter address: ", WoofiAdapter.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
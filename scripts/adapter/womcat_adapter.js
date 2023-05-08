
const { ethers } = require("hardhat");

async function getWombatAdapter() {
    WombatAdapter = await ethers.getContractFactory("WombatAdapter");
    wombatAdapter = await WombatAdapter.deploy();
    await wombatAdapter.deployed();    
    return wombatAdapter
}

async function main() {
    const wombatAdapter = await getWombatAdapter()
    console.log("wombatAdapter address: ", wombatAdapter.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
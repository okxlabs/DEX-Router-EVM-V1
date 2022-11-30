const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {

    _HashflowRouter = "0xE2e3441004E7D377A2D97142e75d465e0dD36aF9"
    WETHAddres = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

    HashflowAdapter = await ethers.getContractFactory("HashflowAdapter");
    HashflowAdapter = await HashflowAdapter.deploy(_HashflowRouter, WETHAddres);
    await HashflowAdapter.deployed();

    console.log(`HashflowAdapter deployed: ${HashflowAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
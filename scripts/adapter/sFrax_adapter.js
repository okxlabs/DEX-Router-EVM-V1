const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    const SFRAX_ADDR = "0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32";
    sFRAXAdapter = await ethers.getContractFactory("sFRAXAdapter");
    sFRAXAdapter = await sFRAXAdapter.deploy(SFRAX_ADDR);
    await sFRAXAdapter.deployed();

    console.log(`sFRAXAdapter deployed: ${sFRAXAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
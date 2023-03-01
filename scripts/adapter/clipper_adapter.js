const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

    ClipperAdapter = await ethers.getContractFactory("ClipperAdapter");
    clipperAdapter = await ClipperAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress,"0xE7b0CE0526fbE3969035a145C9e9691d4d9D216c");
    await clipperAdapter.deployed();

    console.log(`clipperAdapter deployed: ${clipperAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

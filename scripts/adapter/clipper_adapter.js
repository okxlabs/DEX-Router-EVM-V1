const { ethers } = require("hardhat");
const { getConfig } = require("../config");

async function main() {
    const config = getConfig(network.name)
    console.log(config)
    ClipperAdapter = await ethers.getContractFactory("ClipperAdapter");
    clipperAdapter = await ClipperAdapter.deploy(
        config.tokens.WETH.baseTokenAddress, 
        config.contracts.ClipperVerifiedExchange.address
    );
    await clipperAdapter.deployed();

    console.log(`clipperAdapter deployed: ${clipperAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

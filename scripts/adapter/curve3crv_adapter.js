const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("arbitrum");


async function deployAdapter() {
    ZyberV3Adapter = await ethers.getContractFactory("ZyberV3Adapter");
    ZyberV3Adapter = await ZyberV3Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await ZyberV3Adapter.deployed();
}


async function main() {
    ZyberV3Adapter = await deployAdapter();
    console.log(`ZyberV3Adapter deployed: ${ZyberV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

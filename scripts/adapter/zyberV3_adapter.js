const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("arbitrum");

async function deployAdapter() {
    ZyberV3Adapter = await ethers.getContractFactory("ZyberV3Adapter");
    zyberV3Adapter = await ZyberV3Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await zyberV3Adapter.deployed();
    return zyberV3Adapter;
}

async function main() {
    zyberV3Adapter = await deployAdapter();
    console.log(`ZyberV3Adapter deployed: ${zyberV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
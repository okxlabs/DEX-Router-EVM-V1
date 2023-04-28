const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    PancakeV3Adapter = await ethers.getContractFactory("PancakeV3Adapter");
    pancakeV3Adapter = await PancakeV3Adapter.deploy(deployed.base.wNativeToken, deployed.base._PANCAKESWAPV3_FACTROY);
    await pancakeV3Adapter.deployed();

    console.log(`pancakeV3Adapter deployed: ${pancakeV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

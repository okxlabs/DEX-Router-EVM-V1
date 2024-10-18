const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    XeiAdapter = await ethers.getContractFactory("XeiAdapter");
    xeiAdapter = await XeiAdapter.deploy(deployed.base.wNativeToken);
    await xeiAdapter.deployed();

    console.log(`xeiAdapter deployed: ${xeiAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
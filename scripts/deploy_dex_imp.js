const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');
const { dexRouter } = require("./deployed/eth/base");

async function main() {
    console.log(deployed.base);

    DexRouter = await ethers.getContractFactory("DexRouter");
    dexRouter = await DexRouter.deploy();
    await dexRouter.deployed();
    console.log("dexRouter: " + dexRouter.address);
    let tx = await dexRouter.initialize();
    console.log("dexRouter initialized", tx);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

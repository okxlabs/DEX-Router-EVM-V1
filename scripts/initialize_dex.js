const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed.base);

    const proxy = await ethers.getContractAt("TransparentUpgradeableProxy", deployed.base.dexRouter);
    const implAddress = await upgrades.erc1967.getImplementationAddress(proxy.address);
    console.log("Implementation address: ", implAddress);

    const dexRouterImpl = await ethers.getContractAt("DexRouter", implAddress)
    let tx = await dexRouterImpl.initialize();
    console.log("dexRouter initialized: ", tx);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

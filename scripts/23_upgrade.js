const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    const ProxyAdmin = await ethers.getContractAt(
        "ProxyAdmin",
        deployed.base.proxyAdmin
    )
    let proxy = deployed.base.dexRouter
    let newImpl = deployed.base.newImpl
    let tx = await ProxyAdmin.upgrade(proxy, newImpl);
    console.log(tx)



}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

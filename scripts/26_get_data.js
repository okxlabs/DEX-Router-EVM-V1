const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);



    let proxyAdmin = await ethers.provider.getStorageAt(deployed.base.dexRouter, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103");
    proxyAdmin = ethers.utils.getAddress(proxyAdmin.slice(26))

    let proxy = await ethers.getContractAt("TokenApprove", proxyAdmin)
    console.log("owner", await proxy.owner())
    console.log("proxyContractAddress", deployed.base.dexRouter)
    console.log("proxyAdmin", proxyAdmin)
    // console.log("symbol", )
    console.log("newImpl", deployed.base.newImpl)


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

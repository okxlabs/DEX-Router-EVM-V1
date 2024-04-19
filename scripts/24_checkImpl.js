const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    let newImpl = deployed.base.newImpl
    let code = await ethers.provider.getCode(newImpl);
    code = code.toLowerCase()
    let wNativeToken = deployed.base.wNativeToken.replace("0x", "").toLowerCase()
    let wNativeRelayer = deployed.base.wNativeRelayer.replace("0x", "").toLowerCase()
    let tokenApproveProxy = deployed.base.tokenApproveProxy.replace("0x", "").toLowerCase()
    let _FF_FACTORY = deployed.base._FF_FACTORY.replace("0x", "").toLowerCase()
    console.log("wNativeToken included", code.includes(wNativeToken));
    console.log("wNativeRelayer included", code.includes(wNativeRelayer));
    console.log("tokenApproveProxy included", code.includes(tokenApproveProxy));
    console.log("FFFactory included ", code.includes(_FF_FACTORY))

    let oldImpl = await ethers.provider.getStorageAt(deployed.base.dexRouter, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc");
    oldImpl = ethers.utils.getAddress(oldImpl.slice(26))
    console.log("oldImpl", oldImpl)

    let proxyAdmin = await ethers.provider.getStorageAt(deployed.base.dexRouter, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103");
    proxyAdmin = ethers.utils.getAddress(proxyAdmin.slice(26))
    console.log("proxyAdmin", proxyAdmin)





}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

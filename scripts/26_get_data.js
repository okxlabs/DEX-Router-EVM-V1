const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);
    let tokenApprove = deployed.base.tokenApprove
    tokenApprove = await ethers.getContractAt("TokenApprove", tokenApprove)
    console.log("tokenApprove", tokenApprove.address);
    console.log("tokenApproveOwner", await tokenApprove.owner());

    let tokenApproveProxy = deployed.base.tokenApproveProxy
    tokenApproveProxy = await ethers.getContractAt("TokenApproveProxy", tokenApproveProxy)
    console.log("tokenApproveProxy", tokenApproveProxy.address);
    console.log("tokenApproveProxyOwner", await tokenApproveProxy.owner());

    let wNativeRelayer = deployed.base.wNativeRelayer
    wNativeRelayer = await ethers.getContractAt("WNativeRelayer", wNativeRelayer)
    console.log("wNativeRelayer", wNativeRelayer.address);
    console.log("wNativeRelayerOwner", await wNativeRelayer.owner());

    let dexRouter = deployed.base.dexRouter
    dexRouter = await ethers.getContractAt("DexRouter", dexRouter)
    console.log("dexRouter", dexRouter.address);
    console.log("dexRouter owner", await dexRouter.owner());
    console.log("dexRouter admin", await dexRouter.admin());

    let proxyAdmin = await ethers.provider.getStorageAt(deployed.base.dexRouter, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103");
    proxyAdmin = ethers.utils.getAddress(proxyAdmin.slice(26))
    proxyAdmin = await ethers.getContractAt("ProxyAdmin", proxyAdmin)

    console.log("dexRouter proxyAdmin", proxyAdmin.address)
    console.log("dexRouter proxyAdmin owner", await proxyAdmin.owner())



}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

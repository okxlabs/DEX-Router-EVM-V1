const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    const dexRouter = await ethers.getContractAt(
        "DexRouter",
        deployed.base.newImpl
    )
    const gov = "0xAcE2B3E7c752d5deBca72210141d464371b3B9b1"; //新admin
    let owner = await dexRouter.owner()
    console.log("dexrouter owner", owner, gov)
    const wNativeRelayer = await ethers.getContractAt("WNativeRelayer", deployed.base.wNativeRelayer)
    owner = await wNativeRelayer.owner()
    console.log("wnative owner", owner, gov)
    const tokenApproveProxy = await ethers.getContractAt("TokenApproveProxy", deployed.base.tokenApproveProxy)
    owner = await tokenApproveProxy.owner()
    console.log("tokenApproveProxy owner", owner, gov)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    const dexRouter = await ethers.getContractAt(
        "DexRouter",
        deployed.base.newImpl
    )
    const gov = "0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87"; //新admin
    await dexRouter.initialize(gov);

    console.log("set gov finish");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

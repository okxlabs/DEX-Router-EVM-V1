const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    const dexRouter = await ethers.getContractAt(
        "DexRouter",
        deployed.base.newImpl
    )
    const gov = "0xAcE2B3E7c752d5deBca72210141d464371b3B9b1"; //新admin
    const tx = await dexRouter.transferOwnership(gov);
    await tx.wait();
    console.log("set gov finish");
    console.log("owner", await dexRouter.owner())
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

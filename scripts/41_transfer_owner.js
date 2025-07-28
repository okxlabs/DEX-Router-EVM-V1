const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    // DexRouterExactOut
    const dexRouterExactOut = await ethers.getContractAt(
        "DexRouterExactOut",
        deployed.base.newExactOutImpl
    )
    const gov = "0xAcE2B3E7c752d5deBca72210141d464371b3B9b1"; //新admin
    const tx = await dexRouterExactOut.transferOwnership(gov);
    await tx.wait();
    console.log("set gov finish");
    console.log("owner", await dexRouterExactOut.owner())
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

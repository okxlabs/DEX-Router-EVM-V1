const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed.base);
    const newAdmin = "0xE1C7Db7575BABF0d3369835678ec9b7F15c0886B"; //资管账号
    const dexRouter = await ethers.getContractAt(
        "DexRouter",
        deployed.base.newImpl
    );
    await dexRouter.setProtocolAdmin(newAdmin);
    await dexRouter.transferOwnership(newAdmin);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

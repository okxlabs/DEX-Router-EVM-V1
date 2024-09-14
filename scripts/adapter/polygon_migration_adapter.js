const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

    const PolygonMigration = "0x29e7DF7b6A1B2b07b731457f499E1696c60E2C4e";
    const POL = "0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6";
    const MATIC = "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0";
    PolygonMigrationAdapter = await ethers.getContractFactory("PolygonMigrationAdapter");
    PolygonMigrationAdapter = await PolygonMigrationAdapter.deploy(PolygonMigration, MATIC, POL);
    await PolygonMigrationAdapter.deployed();

    console.log(`PolygonMigrationAdapter deployed: ${PolygonMigrationAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

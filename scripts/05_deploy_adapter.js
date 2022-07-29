const { ethers, upgrades } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed.base);

    UniV2Adapter = await ethers.getContractFactory("UniAdapter");
    univ2Adapter = await UniV2Adapter.deploy();
    await univ2Adapter.deployed();

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

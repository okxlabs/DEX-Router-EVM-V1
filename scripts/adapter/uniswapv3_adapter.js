const { ethers } = require("hardhat");

async function main() {
    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    uniV3Adapter = await UniV3Adapter.deploy();
    await uniV3Adapter.deployed();

    console.log(`uniV3Adapter deployed: ${uniV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

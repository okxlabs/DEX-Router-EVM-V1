const { ethers, upgrades } = require("hardhat");

async function main() {
    const ApeAdapter = await ethers.getContractFactory("ApeAdapter");
    const apeAdapter = await upgrades.deployProxy(ApeAdapter);
    await apeAdapter.deployed();

    // 0x291fb70C3ff9973bc82e2CDbe8F70574CaDaE102
    console.log(`ApeAdapter deployed: ${apeAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

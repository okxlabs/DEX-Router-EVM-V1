const { ethers, upgrades } = require("hardhat");

async function main() {
    CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
    CurveV2Adapter = await upgrades.deployProxy(CurveV2Adapter);
    await CurveV2Adapter.deployed();

    console.log(`CurveV2Adapter deployed: ${CurveV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

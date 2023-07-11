const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy(deployed.base.wNativeToken);
    await CurveAdapter.deployed();

    console.log(`CurveAdapter deployed: ${CurveAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

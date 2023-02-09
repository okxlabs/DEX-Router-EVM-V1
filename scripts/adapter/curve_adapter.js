const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await CurveAdapter.deployed();

    console.log(`CurveAdapter deployed: ${CurveAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

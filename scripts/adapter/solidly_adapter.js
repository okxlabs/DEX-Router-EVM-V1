const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
    const router = "0x77784f96C936042A3ADB1dD29C91a55EB2A4219f";
    const WETH = tokenConfig.tokens.WETH.baseTokenAddress;

    SolidlyAdapter = await ethers.getContractFactory("SolidlyAdapter");
    solidlyAdapter = await SolidlyAdapter.deploy(router, WETH);
    await solidlyAdapter.deployed();

    console.log(`solidlyAdapter deployed: ${solidlyAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

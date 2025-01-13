const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("bsc");

async function main() {

    PancakeStableSwapTwoAdapter = await ethers.getContractFactory("PancakeStableSwapTwoAdapter");
    pancakeStableSwapTwoAdapter = await PancakeStableSwapTwoAdapter.deploy(deployed.base.wNativeToken);
    await pancakeStableSwapTwoAdapter.deployed();

    console.log(`PancakeStableSwapTwoAdapter deployed: ${PancakestableAdapter.pancakeStableSwapTwoAdapter}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

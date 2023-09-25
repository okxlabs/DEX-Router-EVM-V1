const { ethers } = require("hardhat");
const { getConfig } = require("../config");
const tokenConfig = getConfig("arb");

async function main() {
    //Arb network
    RamsesV2Adapter = await ethers.getContractFactory("RamsesV2Adapter");
    // WETH : 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    const Factory = "0xAA2cd7477c451E703f3B9Ba5663334914763edF8";
    RamsesV2Adapter = await RamsesV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress, Factory);
    await RamsesV2Adapter.deployed();

    console.log(`RamsesV2Adapter deployed: ${RamsesV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

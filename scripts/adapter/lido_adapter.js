const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function deployAdapter() {
    LidoAdapter = await ethers.getContractFactory("LidoAdapter");
    lidoAdapter = await LidoAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await lidoAdapter.deployed();
    return lidoAdapter;
}

async function main() {
    lidoAdapter = await deployAdapter();
    console.log(`lidoAdapter deployed: ${lidoAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
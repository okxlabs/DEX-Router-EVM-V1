const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";
    const WETH = tokenConfig.tokens.WETH.baseTokenAddress;

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH);
    await bancorAdapter.deployed();

    console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
    const PSMNetwork = "0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A";
    const USDC = tokenConfig.tokens.USDC.baseTokenAddress;
    const DAI = tokenConfig.tokens.DAI.baseTokenAddress;

    PSMAdapter = await ethers.getContractFactory("PSMAdapter");
    psmAdapter = await PSMAdapter.deploy(PSMNetwork, USDC, DAI);
    await psmAdapter.deployed();

    console.log(`psmAdapter deployed: ${psmAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

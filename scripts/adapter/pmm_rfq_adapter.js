const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {

    //1inch V5: 0x1111111254EEB25477B68fb85Ed929f73A960582
    const pmmRFQAddr = "0xbcd0fCD2CEF53B927F7FA75F57D08c28862Ed975"; //KRONOS PMM Protocol

    PmmRFQAdapter = await ethers.getContractFactory("PmmRFQAdapter");
    pmmRFQAdapter = await PmmRFQAdapter.deploy(pmmRFQAddr);
    await pmmRFQAdapter.deployed();

    console.log(`PmmRFQAdapter deployed: ${pmmRFQAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
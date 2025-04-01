
const { ethers } = require("hardhat");

async function main() {
    LitePSMAdapter = await ethers.getContractFactory("LitePSMAdapter");
    litePSMAdapter = await LitePSMAdapter.deploy();
    await litePSMAdapter.deployed();

    console.log(`LitePSMAdapter deployed: ${litePSMAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

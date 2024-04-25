const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    const WMNT = "0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8";
    AgniFinanceAdapter = await ethers.getContractFactory("AgniFinanceAdapter");
    agniFinanceAdapter = await AgniFinanceAdapter.deploy(WMNT);
    await agniFinanceAdapter.deployed();

    console.log(`AgniFinanceAdapter deployed: ${agniFinanceAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
const { ethers } = require("hardhat");

async function main() {
    //BSC network
    NerveFinanceAdapter = await ethers.getContractFactory("NerveFinanceAdapter");
    NerveFinanceAdapter = await NerveFinanceAdapter.deploy();
    await NerveFinanceAdapter.deployed();

    console.log(`NerveFinanceAdapter deployed: ${NerveFinanceAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

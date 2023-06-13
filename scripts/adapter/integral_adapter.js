const { ethers } = require("hardhat");

async function main() {
    IntegralAdapter = await ethers.getContractFactory("IntegralAdapter");
    integralAdapter = await IntegralAdapter.deploy("0xd17b3c9784510E33cD5B87b490E79253BcD81e2E");//eth
    await integralAdapter.deployed();

    console.log(`integralAdapter deployed: ${integralAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

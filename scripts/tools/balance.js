const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Deployer address:", deployer.address);
    console.log("Balance:", ethers.utils.formatEther(balance), "BNB");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

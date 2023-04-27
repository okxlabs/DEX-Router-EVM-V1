const { ethers } = require("hardhat");


async function main() {
    const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    const vault = "0xa82f327BBbF0667356D2935C6532d164b06cEced"
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    balancerV2Adapter = await BalancerV2Adapter.deploy(vault, WBNB);
    await balancerV2Adapter.deployed();

    console.log(`balancerV2Adapter deployed: ${balancerV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

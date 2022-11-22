const { ethers, upgrades } = require("hardhat");

async function main() {
    let FraxswapAdapter = await ethers.getContractFactory("FraxswapAdapter");
    FraxswapAdapter = await FraxswapAdapter.deploy();
    await FraxswapAdapter.deployed();

    console.log(`FraxswapAdapter deployed: ${FraxswapAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

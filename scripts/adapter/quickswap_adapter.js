const { ethers } = require("hardhat");


async function main() {
    QuickswapAdapter = await ethers.getContractFactory("QuickswapAdapter");
    quickswapAdapter = await QuickswapAdapter.deploy();
    await quickswapAdapter.deployed();

    console.log(`quickswapAdapter deployed: ${quickswapAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

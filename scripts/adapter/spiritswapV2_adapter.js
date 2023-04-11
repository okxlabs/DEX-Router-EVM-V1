const { ethers } = require("hardhat");


async function main() {
    SpiritswapV2Adapter = await ethers.getContractFactory("SpiritswapV2Adapter");
    spiritswapV2Adapter = await SpiritswapV2Adapter.deploy();
    await spiritswapV2Adapter.deployed();

    console.log(`spiritswapV2Adapter deployed: ${spiritswapV2Adapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");


async function main() {

    IronswapAdapter = await ethers.getContractFactory("IronswapAdapter");
    IronswapAdapter = await IronswapAdapter.deploy();
    await IronswapAdapter.deployed();
    console.log(`IronswapAdapter deployed: ${IronswapAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

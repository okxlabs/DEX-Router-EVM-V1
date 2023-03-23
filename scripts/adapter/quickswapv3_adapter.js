const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    Quickswapv3Adapter = await ethers.getContractFactory("Quickswapv3Adapter");
    quickswapv3Adapter = await Quickswapv3Adapter.deploy(deployed.base.wNativeToken);
    await quickswapv3Adapter.deployed();

    console.log(`quickswapv3Adapter deployed: ${quickswapv3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");


async function main() {
    SyncSwapAdapter = await ethers.getContractFactory("SyncSwapAdapter");
    syncSwapAdapter = await SyncSwapAdapter.deploy();
    await syncSwapAdapter.deployed();

    console.log(`syncSwapAdapter deployed: ${syncSwapAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

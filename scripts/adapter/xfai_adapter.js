const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    XfaiAdapter = await ethers.getContractFactory("XfaiAdapter");
    xfaiAdapter = await XfaiAdapter.deploy();
    await xfaiAdapter.deployed();

    console.log(`xfaiAdapter deployed: ${xfaiAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

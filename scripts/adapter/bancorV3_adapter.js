const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    const BancorNetworkV3 = "0xeEF417e1D5CC832e619ae18D2F140De2999dD4fB";
    const BancorNetworkV3Info = "0x8E303D296851B320e6a697bAcB979d13c9D6E760";

    BancorV3Adapter = await ethers.getContractFactory("BancorV3Adapter");
    bancorV3Adapter = await BancorV3Adapter.deploy(BancorNetworkV3, BancorNetworkV3Info, deployed.base.wNativeToken);
    await bancorV3Adapter.deployed();

    console.log(`bancorV3Adapter deployed: ${bancorV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

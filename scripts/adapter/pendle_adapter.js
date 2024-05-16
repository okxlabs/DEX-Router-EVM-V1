const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
    const router = "0x00000000005BBB0EF59571E58418F9a4357b68A0"; //arb, eth, bsc, op
    PendleAdapter = await ethers.getContractFactory("PendleAdapter");
    PendleAdapter = await PendleAdapter.deploy(router);
    await PendleAdapter.deployed();

    console.log(`PendleAdapter deployed: ${PendleAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

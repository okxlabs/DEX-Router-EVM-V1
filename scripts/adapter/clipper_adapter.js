const { ethers } = require("hardhat");
const { getConfig } = require("../config");
const deployed = require("../deployed");

async function main() {
    const config = getConfig(network.name);
    const wrapNativeToken = deployed.base.wNativeToken;

    ClipperAdapter = await ethers.getContractFactory("ClipperAdapter");
    clipperAdapter = await ClipperAdapter.deploy(
        wrapNativeToken, 
        config.contracts.ClipperVerifiedExchange.address
    );
    await clipperAdapter.deployed();

    // clipperAdapter = await ethers.getContractAt(
    //     "ClipperAdapter",
    //     "0x12e55236d0743999716ebAcBd1FE07F63719b0dF"
    // );
    // console.log(await clipperAdapter.WETH_ADDRESS());
    // console.log(await clipperAdapter.CLIPPER_ROUTER());

    console.log(`clipperAdapter deployed: ${clipperAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

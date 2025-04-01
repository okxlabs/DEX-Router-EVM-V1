const { ethers, network } = require("hardhat");
const { getConfig } = require("../config");

async function main() {
    const config = getConfig(network.name)

    DODOV1Adapter = await ethers.getContractFactory("DODOV1Adapter");
    dodoV1Adapter = await DODOV1Adapter.deploy(config.contracts._DODO_SELL_HELPER_.address);
    await dodoV1Adapter.deployed();

    console.log(`dodoV1Adapter deployed: ${dodoV1Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

    
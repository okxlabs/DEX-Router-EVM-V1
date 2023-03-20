const { ethers, network } = require("hardhat");
const { getConfig } = require("../config");

async function main() {
    const config = getConfig(network.name);
    const NomiswapAdapter = await ethers.getContractFactory("NomiswapAdapter");
    const nomiswapAdapter = await NomiswapAdapter.deploy(
        config.contracts.NomiswapFactory.address,
        config.contracts.NomiswapStableFactory.address
    );
    await nomiswapAdapter.deployed();

    console.log(`nomiswapAdapter deployed: ${nomiswapAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

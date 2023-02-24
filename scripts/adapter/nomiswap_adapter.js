const { ethers } = require("hardhat");
const { getConfig } = require("../config");

async function main() {
    const tokenConfig = getConfig("eth");
    const NomiswapAdapter = await ethers.getContractFactory("NomiswapAdapter");
    const nomiswapAdapter = await NomiswapAdapter.deploy(
        tokenConfig.contracts.NomiswapFactory.address,
        tokenConfig.contracts.NomiswapStableFactory.address
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

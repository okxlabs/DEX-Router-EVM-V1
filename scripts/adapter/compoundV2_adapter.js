const { ethers } = require("hardhat");


async function main() {
    // ethereum
    console.log("deploy etherum compoundV2 adapter, for the polygon network, please uncomment the main_polygon func, which changes the WMATIC address")
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    CompoundAdapter = await ethers.getContractFactory("CompoundAdapter");
    CompoundAdapter = await CompoundAdapter.deploy(WETH);
    await CompoundAdapter.deployed();

    console.log(`ethereum CompoundAdapter deployed: ${CompoundAdapter.address}`);
}

// async function main() {
//     // ethereum
//     console.log("deploy polygon compoundV2 adapter")
//     const WMATIC = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
//     CompoundAdapter = await ethers.getContractFactory("CompoundAdapter");
//     CompoundAdapter = await CompoundAdapter.deploy(WMATIC);
//     await CompoundAdapter.deployed();

//     console.log(`polygon CompoundAdapter deployed: ${CompoundAdapter.address}`);
// }

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");

// BSC: 
// factory: 0xd7de110bd452aab96608ac3750c3730a17993de0
// WBNB: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
// IZumiAdapter deployed: 0xD35f165c03A27d21da5D7F5096Fd66668D5dFFA0

// arb
// factory: 0x45e5F26451CDB01B0fA1f8582E0aAD9A6F27C218
// WETH: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
// IZumiAdapter deployed: 0xbC1258cE5FE29d2Cd76F686F3A2Ac92bf1c6EbF0

// polygon
// facotry: 0x3EF68D3f7664b2805D4E88381b64868a56f88bC4
// WETH: 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
// IZumiAdapter deployed: 0xA98DF73fA93B6dD994C83D661772d14d393dd87B

// conflux epsace
// factory: 0x110dE362cc436D7f54210f96b8C7652C2617887D
// WCFX: 0x14b2d3bc65e74dae1030eafd8ac30c533c976a9b
// IZumiAdapter deployed: 0x022fBeFfA9B0422F0A2Eab63A75533c48a13cC38


async function deployIzumiAdapter() {
    factory = "0x110dE362cc436D7f54210f96b8C7652C2617887D"
    IZumiAdapter = await ethers.getContractFactory("IZumiAdapter");
    IZumiAdapter = await IZumiAdapter.deploy(
        "0x14b2d3bc65e74dae1030eafd8ac30c533c976a9b",
        factory
    );
    await IZumiAdapter.deployed();
    return IZumiAdapter
}

async function main() {
    
    IZumiAdapter = await deployIzumiAdapter();
    console.log(`IZumiAdapter deployed: ${IZumiAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

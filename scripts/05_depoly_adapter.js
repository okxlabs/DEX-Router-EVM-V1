const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    UniV2Adapter = await ethers.getContractFactory("UniAdapter");
    univ2Adapter = await UniV2Adapter.deploy();
    await univ2Adapter.deployed();

    console.log("univ2Adapter: " + univ2Adapter.address);

    // BakeryAdapter = await ethers.getContractFactory("BakeryAdapter");
    // bakeryAdapter = await BakeryAdapter.deploy();
    // await bakeryAdapter.deployed();
    //
    // console.log("bakeryAdapter: " + bakeryAdapter.address);
    //
    // KyberAdapter = await ethers.getContractFactory("KyberAdapter");
    // kyberAdapter = await KyberAdapter.deploy();
    // await kyberAdapter.deployed();
    //
    // console.log("kyberAdapter: " + kyberAdapter.address);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");


async function main() {
    TridentAdapter = await ethers.getContractFactory("TridentAdapter");
    tridentAdapter = await TridentAdapter.deploy("0xc35DADB65012eC5796536bD9864eD8773aBc74C4");
    //op ：0xc35DADB65012eC5796536bD9864eD8773aBc74C4
    //polygon ：0x0319000133d3AdA02600f0875d2cf03D442C3367
    //bsc：0xF5BCE5077908a1b7370B9ae04AdC565EBd643966
    //arbitrum：0x74c764D41B77DBbb4fe771daB1939B00b146894A

    await tridentAdapter.deployed();

    console.log(`tridentAdapter deployed: ${tridentAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

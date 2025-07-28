const { ethers } = require("hardhat");

async function main() {
    DragonV2Adapter = await ethers.getContractFactory("DragonV2Adapter");
    dragonV2Adapter = await DragonV2Adapter.deploy("0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7");
    
    await dragonV2Adapter.deployed();

    console.log(`DragonV2Adapter deployed: ${dragonV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
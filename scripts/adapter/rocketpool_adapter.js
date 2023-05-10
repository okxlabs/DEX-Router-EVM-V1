const { ethers } = require("hardhat");
const { getConfig } = require("../config");
const tokenConfig = getConfig("eth");

async function main() {
    const DEPOSITPOOL = "0xDD3f50F8A6CafbE9b31a427582963f465E745AF8";
    RocketpoolAdapter = await ethers.getContractFactory("RocketpoolAdapter");
    rocketpoolAdapter = await RocketpoolAdapter.deploy(tokenConfig.tokens.rETH.baseTokenAddress,DEPOSITPOOL,tokenConfig.tokens.WETH.baseTokenAddress);
    await rocketpoolAdapter.deployed();
  
    console.log(`rocketpoolsAdapter deployed: ${rocketpoolAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

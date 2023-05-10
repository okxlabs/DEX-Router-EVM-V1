const { ethers } = require("hardhat");



async function main() {
    const LENDINGPOOL = "0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf";//polygon
    //const LENDINGPOOL = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9";//eth
    AaveV2Adapter = await ethers.getContractFactory("AaveV2Adapter");
    aaveV2Adapter = await AaveV2Adapter.deploy(LENDINGPOOL);
    await aaveV2Adapter.deployed();
  
    console.log(`aaveV2Adapter deployed: ${aaveV2Adapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

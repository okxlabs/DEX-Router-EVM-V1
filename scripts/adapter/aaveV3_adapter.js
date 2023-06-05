const { ethers } = require("hardhat");



async function main() {

    const V3POOL = "0x794a61358d6845594f94dc1db02a252b5b4814ad";//polygon or op、arb、ftm、avax
    //const V3POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";//eth
    AaveV3Adapter = await ethers.getContractFactory("AaveV3Adapter");
    aaveV3Adapter = await AaveV3Adapter.deploy(V3POOL);
    await aaveV3Adapter.deployed();

    console.log(`aaveV3Adapter deployed: ${aaveV3Adapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

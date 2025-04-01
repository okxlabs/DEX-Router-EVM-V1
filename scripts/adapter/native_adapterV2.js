const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    NativePmmAdapterV2 = await ethers.getContractFactory("NativePmmAdapterV2");
    if (deployed.base.wNativeToken != "" && deployed.base.wNativeToken.length > 10) {
        console.log("wnative address", deployed.base.wNativeToken)
        NativePmmAdapterV2 = await NativePmmAdapterV2.deploy(deployed.base.wNativeToken);
        await NativePmmAdapterV2.deployed();
        console.log(`NativePmmAdapterV2 deployed: ${NativePmmAdapterV2.address}`);
    } else {
        console.log("wnative address is null")
    }



}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
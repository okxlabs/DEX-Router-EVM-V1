const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    //router address for other chains: https://github.com/hashflownetwork/x-protocol/blob/main/evm/deployed-contracts/IHashflowRouter.json
    const router = "0x55084eE0fEf03f14a305cd24286359A35D735151";
    const weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    HashflowV3Adapter = await ethers.getContractFactory("HashflowV3Adapter");
    HashflowV3Adapter = await HashflowV3Adapter.deploy(router, weth);
    await HashflowV3Adapter.deployed();

    console.log(`HashflowV3Adapter deployed: ${HashflowV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
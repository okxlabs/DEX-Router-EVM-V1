const { ethers } = require("hardhat");


async function main() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

    OneinchV1Adapter = await ethers.getContractFactory("OneinchV1Adapter");
    OneinchV1Adapter = await OneinchV1Adapter.deploy(WETH);
    await OneinchV1Adapter.deployed();

    console.log(`OneinchV1Adapter deployed: ${OneinchV1Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

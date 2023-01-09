const { ethers } = require("hardhat");

const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

async function main() {
    KyberElasticAdapter = await ethers.getContractFactory("KyberElasticAdapter");
    KyberElasticAdapter = await KyberElasticAdapter.deploy(WETHAddress);
    await KyberElasticAdapter.deployed();

    console.log(`KyberElasticAdapter deployed: ${KyberElasticAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

const { ethers } = require("hardhat");

async function main() {
    const wETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const etherfiLp = "0x308861A430be4cce5502d0A12724771Fc6DaF216";

    EtherFiEethAdapter = await ethers.getContractFactory("EtherFiEethAdapter");
    etherFiEethAdapter = await EtherFiEethAdapter.deploy(wETH, etherfiLp);
    await etherFiEethAdapter.deployed();

    console.log(`etherFiEethAdapter deployed: ${etherFiEethAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
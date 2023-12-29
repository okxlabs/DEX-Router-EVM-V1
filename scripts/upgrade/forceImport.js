const { ethers } = require("hardhat");

async function main() {
    const DexRouter = await ethers.getContractFactory("DexRouter");
    const deployment = await upgrades.forceImport('0x1D80c49BbBCd1C0911346656B529DF9E5c2F783d', DexRouter);
    console.log("Proxy imported from:", deployment.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

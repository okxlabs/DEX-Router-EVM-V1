
const { ethers } = require("hardhat");
const _WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

async function getZeroExAdapter() {
    ZeroExAdapter = await ethers.getContractFactory("ZeroExAdapter");
    ZeroExAdapter = await ZeroExAdapter.deploy(_WETH);
    await ZeroExAdapter.deployed();    
    return ZeroExAdapter
}

async function main() {
    const ZeroExAdapter = await getZeroExAdapter()
    console.log("ZeroExAdapter address: ", ZeroExAdapter.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
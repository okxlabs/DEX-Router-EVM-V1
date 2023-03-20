const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");


pool_lp_token = "0x6c3f90f043a72fa612cbac8115ee7e52bde6e490"
async function deployAdapter() {
    Curve3poolLPAdapter = await ethers.getContractFactory("Curve3poolLPAdapter");
    Curve3poolLPAdapter = await Curve3poolLPAdapter.deploy(pool_lp_token);
    await Curve3poolLPAdapter.deployed();
    return Curve3poolLPAdapter
}


async function main() {
    Curve3poolLPAdapter = await deployAdapter();
    console.log(`Curve3poolLPAdapter deployed: ${Curve3poolLPAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

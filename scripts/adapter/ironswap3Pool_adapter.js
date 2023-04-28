const { ethers } = require("hardhat");


async function main() {
    // only polygon needs to deploy this, because on AVAX and fantom, 
    // there is only three pool, no meta pool 
    console.log("for iron adapter, only polygon needs to deploy this, because on AVAX and fantom, there is only three pool, no meta pool ");
    const threePool = "0x837503e8A8753ae17fB8C8151B8e6f586defCb57"
    Ironswap3PoolLpAdapter = await ethers.getContractFactory("Ironswap3PoolLpAdapter");
    Ironswap3PoolLpAdapter = await Ironswap3PoolLpAdapter.deploy(threePool);
    console.log(`Ironswap3PoolLpAdapter deployed: ${Ironswap3PoolLpAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

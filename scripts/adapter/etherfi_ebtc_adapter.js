const { ethers } = require("hardhat");

async function main() {
    const eBTC = "0x657e8C867D8B37dCC18fA4Caead9C45EB088C642";
    const teller = "0x6Ee3aaCcf9f2321E49063C4F8da775DdBd407268";

    EtherFiEbtcAdapter = await ethers.getContractFactory("EtherFiEbtcAdapter");
    etherFiEbtcAdapter = await EtherFiEbtcAdapter.deploy(teller, eBTC);
    await etherFiEbtcAdapter.deployed();

    console.log(`etherFiEbtcAdapter deployed: ${etherFiEbtcAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

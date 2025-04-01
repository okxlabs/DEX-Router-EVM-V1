const { ethers } = require("hardhat");

async function main() {
    const weETH = "0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee";

    EtherFiWeethAdapter = await ethers.getContractFactory("EtherFiWeethAdapter");
    etherFiWeethAdapter = await EtherFiWeethAdapter.deploy(weETH);
    await etherFiWeethAdapter.deployed();

    console.log(`etherFiWeethAdapter deployed: ${etherFiWeethAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
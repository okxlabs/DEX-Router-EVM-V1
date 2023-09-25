const { ethers } = require("hardhat");


async function main() {
    snxProxyAddr = "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F";//eth
    SynthetixExchangeAtomicallyAdapter = await ethers.getContractFactory("SynthetixExchangeAtomicallyAdapter");
    synthetixExchangeAtomicallyAdapter = await SynthetixExchangeAtomicallyAdapter.deploy(snxProxyAddr);
    await synthetixExchangeAtomicallyAdapter.deployed();

    console.log(`synthetixExchangeAtomicallyAdapter deployed: ${synthetixExchangeAtomicallyAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

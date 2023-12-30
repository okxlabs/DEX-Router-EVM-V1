const { ethers } = require("hardhat");


async function main() {
    snxProxyAddr = "0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4";//op
    SynthetixExchangeWithTrackingAdapter = await ethers.getContractFactory("SynthetixExchangeWithTrackingAdapter");
    synthetixExchangeWithTrackingAdapter = await SynthetixExchangeWithTrackingAdapter.deploy(snxProxyAddr);
    await synthetixExchangeWithTrackingAdapter.deployed();

    console.log(`synthetixExchangeWithTrackingAdapter deployed: ${synthetixExchangeWithTrackingAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

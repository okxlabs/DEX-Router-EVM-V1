const { ethers } = require("hardhat");
const deployed = require('../../scripts/deployed');

async function main() {

  console.log(deployed);

  dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );

  marketMaker = await ethers.getContractAt(
    "MarketMaker",
    deployed.base.marketMaker
  );

  wNativeRelayer = await ethers.getContractAt(
    "WNativeRelayer",
    deployed.base.wNativeRelayer
  );

  marketMakerProxyAdmin = await ethers.getContractAt(
    "ProxyAdmin",
    deployed.base.marketMakerProxyAdmin
  );


  NewMarketMaker = await ethers.getContractFactory("MarketMaker");
  newMarketMaker = await NewMarketMaker.deploy();
  await newMarketMaker.deployed();
  await marketMakerProxyAdmin.upgrade(marketMaker.address, newMarketMaker.address);
  await marketMaker.setWNativeRelayer(wNativeRelayer.address);
  await marketMaker.setDexRouter(dexRouter.address);
  await wNativeRelayer.setCallerOk([marketMaker.address],true);

  console.log("update finish");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

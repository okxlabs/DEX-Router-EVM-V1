const { ethers } = require("hardhat");
const { config } = require("../config");

async function deployAdapter(adapterName, args) {
  Adapter = await ethers.getContractFactory(adapterName);
  adapter = await Adapter.deploy(...args);
  await adapter.deployed();

  console.log(`${adapterName} deployed: ${adapter.address}`);
}

async function main() {

  const adapterList = [
    'BalancerAdapter',
    'BalancerV2Adapter',
    'BancorAdapter',
    'CurveAdapter',
    'CurveV2Adapter',
    'KyberAdapter',
    'PancakeAdapter',
    'UniAdapter',
    'UniV3Adapter'
  ]

  const adapterArgs = [
    [], // BalancerAdapter
    [config.contracts.BalancerVault.address, config.tokens.WETH.baseTokenAddress], // BalancerV2Adapter
    [config.contracts.BancorNetwork.address, config.tokens.WETH.baseTokenAddress], // BancorAdapter
    [], // CurveAdapter
    [config.tokens.WETH.baseTokenAddress], // CurveV2Adapter
    [], // KyberAdapter
    [], // PancakeAdapter
    [], // UniAdapter
    [config.tokens.WETH.baseTokenAddress], // UniV3Adapter
  ]

  for (let i = 0; i < adapterList.length; i++) {
    await deployAdapter(adapterList[i], adapterArgs[i]);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
      console.error(error);
      process.exit(1);
  });

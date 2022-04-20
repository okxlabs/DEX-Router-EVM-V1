const { ethers } = require("hardhat");
const deployed = require("../../../deployed");

const FOREVER = '2000000000';

const initDexRouter = async () => {
  TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
  tokenApproveProxy = await TokenApproveProxy.deploy();
  await tokenApproveProxy.initialize();
  await tokenApproveProxy.deployed();

  TokenApprove = await ethers.getContractFactory("TokenApprove");
  tokenApprove = await TokenApprove.deploy();
  await tokenApprove.initialize(tokenApproveProxy.address);
  await tokenApprove.deployed();

  DexRouter = await ethers.getContractFactory("DexRouter");
  const dexRouter = await upgrades.deployProxy(
    DexRouter
  )
  await dexRouter.deployed();
  await dexRouter.setApproveProxy(tokenApproveProxy.address);

  await tokenApproveProxy.addProxy(dexRouter.address);
  await tokenApproveProxy.setTokenApprove(tokenApprove.address);

  WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
  wNativeRelayer = await WNativeRelayer.deploy();
  await wNativeRelayer.deployed();
  await wNativeRelayer.initialize("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
  await wNativeRelayer.setCallerOk([dexRouter.address], [true]);

  return { dexRouter, tokenApprove }
}

const direction = function(token0, token1) {
  return token0 > token1 ? 0 : 8;
}

module.exports = {
  initDexRouter,
  direction,
  FOREVER
}

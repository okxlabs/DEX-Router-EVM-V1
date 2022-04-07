const { ethers } = require("hardhat");

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

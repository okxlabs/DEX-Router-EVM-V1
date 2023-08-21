const { ethers } = require("hardhat");
const deployed = require("../../../deployed");

const FOREVER = '2000000000';
const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }

const initDexRouter = async (weth) => {
  TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
  tokenApproveProxy = await TokenApproveProxy.deploy();
  await tokenApproveProxy.initialize();
  await tokenApproveProxy.deployed();

  if (weth){
    wnativeToken = weth
  }else{
    wnativeToken = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
  }

  TokenApprove = await ethers.getContractFactory("TokenApprove");
  tokenApprove = await TokenApprove.deploy();
  await tokenApprove.initialize(tokenApproveProxy.address);
  await tokenApprove.deployed();

  DexRouter = await ethers.getContractFactory("DexRouter");
  const dexRouter = await upgrades.deployProxy(
    DexRouter
  )
  await dexRouter.deployed();
  // await dexRouter.setApproveProxy(tokenApproveProxy.address);

  await tokenApproveProxy.addProxy(dexRouter.address);
  await tokenApproveProxy.setTokenApprove(tokenApprove.address);

  WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
  wNativeRelayer = await WNativeRelayer.deploy();
  await wNativeRelayer.deployed();
  await wNativeRelayer.initialize(wnativeToken);
  await wNativeRelayer.setCallerOk([dexRouter.address], [true]);
  // await dexRouter.setWNativeRelayer(wNativeRelayer.address);

  return { dexRouter, tokenApprove }
}

const getWeight = function(weight) {
  return ethers.utils.hexZeroPad(weight, 2).replace('0x', '');
}

const direction = function(token0, token1) {
  return token0 < token1 ? 0 : 8;
}

const packRawData = function(token0, token1, weight, poolAddr) {
  return "0x" +
  direction(token0, token1) +
  "0000000000000000000" +
  getWeight(weight) +
  poolAddr.replace("0x", "")
}

module.exports = {
  initDexRouter,
  direction,
  getWeight,
  packRawData,
  FOREVER,
  ETH
}

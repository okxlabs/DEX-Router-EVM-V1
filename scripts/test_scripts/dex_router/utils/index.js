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

  const accountAddress = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
  await startMockAccount([accountAddress]);
  account = await ethers.getSigner(accountAddress);

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");
  wNativeRelayer = await ethers.getContractAt("WNativeRelayer", "0x5703B683c7F928b721CA95Da988d73a3299d4757")

  await wNativeRelayer.connect(account).setCallerOk([dexRouter.address], [true]);
  
  
  // console.log(wNativeRelayer.address);

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
  FOREVER
}

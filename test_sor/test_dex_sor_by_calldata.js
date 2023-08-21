const { ethers } = require('hardhat')
const { expect } = require('chai');
require("../scripts/tools");

describe("Smart route path test by calldata", function() {

  const FOREVER = '2000000000';
  let router, tokenApprove, dexRouter, wNativeRelayer, tokenApproveProxy;
  let account;

  before(async () => {
    const WETH9 = await ethers.getContractFactory("WETH9");
    weth = await WETH9.deploy();

    WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
    wNativeRelayer = await WNativeRelayer.deploy();
    await wNativeRelayer.deployed();
    await wNativeRelayer.initialize(weth.address);
  });

  beforeEach(async () => {

    // const block = await ethers.provider.getBlock(14874123);
    // await setNextBlockTimeStamp(block.timestamp + 60);

    const accountAddress = "0x55FE002aefF02F77364de339a1292923A15844B8";
    await startMockAccount([accountAddress]);
    account = await ethers.getSigner(accountAddress);
    // [owner, alice, bob, liquidity] = await ethers.getSigners();

    await initDexRouter();
  });

  // {
  //   "error": "RuntimeError: VM Exception while processing transaction: revert",
  //   "inputToken": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
  //   "outputToken": "0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c",
  //   "inputAmount": "10000000000000",
  //   "blockNumber": 14874123,
  //   "chainId": 0,
  // }

  it("test unidata", async() => {

    fromToken = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
    toToken = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
    // fromTokenAmount = "10000000000000";

    console.log("test 1");

    // check BalanceOf 
    InputToken = await ethers.getContractAt(
        "MockERC20",
        fromToken
      );
    OutputToken = await ethers.getContractAt(
        "MockERC20",
        toToken
      );

    console.log("before InputToken Balance: " + await InputToken.balanceOf(account.address));
    console.log("before OutputToken Balance: " + await OutputToken.balanceOf(account.address));
    console.log("dex router address: ", dexRouter.address);


    // await InputToken.connect(account).approve(tokenApprove.address, ethers.constants.MaxUint256);
    await InputToken.connect(account).approve(tokenApprove.address, await InputToken.balanceOf(account.address));

    const calldata = "0xce8c4316000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000013e9fee841b0230000000000000000000000000000000000000000000000000000000062f1fefd0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000003a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f38c9faa460fe4bdca1d473e2fda7ef5182649cb0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f38c9faa460fe4bdca1d473e2fda7ef5182649cb000000000000000000000000000000000000000000000000000000000000000180000000000000000000271075c23271661d9d143dcb617222bc4bec783eff3400000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    tx = {
        "from": account.address,
        "to": dexRouter.address,
        "data": calldata,
        "gasLimit": 80000000
    }
    
    const txRes = await account.sendTransaction({ ...tx });

    console.log("after InputToken Balance: " + await InputToken.balanceOf(account.address));
    console.log("after OutputToken Balance: " + await OutputToken.balanceOf(account.address));
    
  });


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
    dexRouter = await upgrades.deployProxy(
      DexRouter
    )
    await dexRouter.deployed();
    // await dexRouter.setApproveProxy(tokenApproveProxy.address);

    await tokenApproveProxy.addProxy(dexRouter.address);
    await tokenApproveProxy.setTokenApprove(tokenApprove.address);

    await wNativeRelayer.setCallerOk([dexRouter.address], [true]);
  }

});

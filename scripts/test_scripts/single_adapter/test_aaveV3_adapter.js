const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for aaveV2(eth、polygon)
async function execute() {

  //compared tx
  //https://polygonscan.com/tx/0x1585cbc75ee8274187cf68f83595406fbf0013712d1d1e030d9d75e1162c928f

  // Network polygon
  await setForkNetWorkAndBlockNumber('polygon',43080909);
  //await setForkNetWorkAndBlockNumber('eth',17327904);

  const tokenConfig = getConfig("polygon");
  //const tokenConfig = getConfig("eth");

  
  const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  Base = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDC.baseTokenAddress
  )
  Quote = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.aPolUSDC.baseTokenAddress// aave polygon USDC
    //tokenConfig.tokens.aEthUSDC.baseTokenAddress// aave Ethereum USDC
  )

  const V3POOL = "0x794a61358d6845594f94dc1db02a252b5b4814ad";//polygon or op、arb、ftm、avax
  //const V3POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";//eth
  AaveV3Adapter = await ethers.getContractFactory("AaveV3Adapter");
  aaveV3Adapter = await AaveV3Adapter.deploy(V3POOL);
  await aaveV3Adapter.deployed();

  const poolAddr = V3POOL;//lendingpool

  console.log("before Base Balance: " + await Base.balanceOf(account.address));
  console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1USDC to adapter
  await Base.connect(account).transfer(aaveV3Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

  // sell base token 
  rxResult = await aaveV3Adapter.sellBase(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address","address","bool"],
        [Base.address,Quote.address,true]
      )
  );

  console.log("after Base Balance: " + await Base.balanceOf(account.address));
  console.log("after Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1 aPolUSDC to adapter
  await Quote.connect(account).transfer(aaveV3Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.aPolUSDC.decimals));
  //await Quote.connect(account).transfer(aaveV3Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.aEthUSDC.decimals));      

  // sell quote token
  rxResult = await aaveV3Adapter.sellQuote(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address","address","bool"],
        [Quote.address,Base.address,false]
      )
  );

  console.log("after Base Balance: " + await Base.balanceOf(account.address));
  console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
}

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

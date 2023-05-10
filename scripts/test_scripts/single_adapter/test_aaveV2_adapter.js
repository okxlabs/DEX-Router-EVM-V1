const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for aaveV2(eth、polygon)
async function execute() {

  //compared tx
  //https://polygonscan.com/tx/0xaf016dc7b318721753ac602bb2bf224a3c25f86bbea0f3c55bbb12836633ac52

  // Network polygon
  await setForkNetWorkAndBlockNumber('polygon',42438815);
  //await setForkNetWorkAndBlockNumber('eth',17214238);

  const tokenConfig = getConfig("polygon");
  //const tokenConfig = getConfig("eth");

  
  const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  Base = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDT.baseTokenAddress
  )
  Quote = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.amUSDT.baseTokenAddress// aave matic USDT
    //tokenConfig.tokens.aUSDT.baseTokenAddress// aave USDT
  )

  const LENDINGPOOL = "0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf";//polygon
  //const LENDINGPOOL = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9";//eth
  AaveV2Adapter = await ethers.getContractFactory("AaveV2Adapter");
  aaveV2Adapter = await AaveV2Adapter.deploy(LENDINGPOOL);
  await aaveV2Adapter.deployed();

  const poolAddr = LENDINGPOOL;//lendingpool

  console.log("before Base Balance: " + await Base.balanceOf(account.address));
  console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1USDT to adapter
  await Base.connect(account).transfer(aaveV2Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));

  // sell base token 
  rxResult = await aaveV2Adapter.sellBase(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address","address","bool"],
        [Base.address,Quote.address,true]
      )
  );

  console.log("after Base Balance: " + await Base.balanceOf(account.address));
  console.log("after Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1 amUSDT to adapter
  await Quote.connect(account).transfer(aaveV2Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.amUSDT.decimals));
  //await Quote.connect(account).transfer(aaveV2Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.aUSDT.decimals));      

  // sell quote token
  rxResult = await aaveV2Adapter.sellQuote(
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

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for WrappedSynthetix(eth、op)
async function execute() {

  //compared tx
  //

  // Network 
  // await setForkNetWorkAndBlockNumber('op',42438815);
  await setForkNetWorkAndBlockNumber('eth',17967445);

  //const tokenConfig = getConfig("op");
  const tokenConfig = getConfig("eth");

  
  const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

  Base = await ethers.getContractAt(
    "MockERC20",
    //tokenConfig.tokens.DAI.baseTokenAddress
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  Quote = await ethers.getContractAt(
    "MockERC20",
    //tokenConfig.tokens.sUSD.baseTokenAddress
    tokenConfig.tokens.sETH.baseTokenAddress
  )

  
  WrappedSynthetixAdapter = await ethers.getContractFactory("WrappedSynthetixAdapter");
  wrappedSynthetixAdapter = await WrappedSynthetixAdapter.deploy();
  await wrappedSynthetixAdapter.deployed();

  const wrapper = "0xCea392596F1AB7f1d6f8F241967094cA519E6129";
  //wrapper(op susd):"0xad32aA4Bff8b61B4aE07E3BA437CF81100AF0cD7"
  //wrapper(op seth):"0x6202A3B0bE1D222971E93AaB084c6E584C29DB70"
  //wrapper(eth susd):"0xE01698760Ec750f5f1603CE84C148bAB99cf1A74"
  //wrapper(eth seth):"0xCea392596F1AB7f1d6f8F241967094cA519E6129"
  const poolAddr = wrapper;

  console.log("before Base Balance: " + await Base.balanceOf(account.address));
  console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1dai to adapter
  // await Base.connect(account).transfer(wrappedSynthetixAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.DAI.decimals));
  await Base.connect(account).transfer(wrappedSynthetixAdapter.address, ethers.utils.parseUnits('0.01',tokenConfig.tokens.WETH.decimals));
  console.log("flag");

  // sell base token 
  rxResult = await wrappedSynthetixAdapter.sellBase(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address","address","address"],
        [Base.address,Quote.address,wrapper]
      )
  );

  console.log("after Base Balance: " + await Base.balanceOf(account.address));
  console.log("after Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1 sUSD to adapter
  // await Quote.connect(account).transfer(wrappedSynthetixAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.sUSD.decimals));
  await Quote.connect(account).transfer(wrappedSynthetixAdapter.address, ethers.utils.parseUnits('0.00999',tokenConfig.tokens.sETH.decimals));      
  
  // sell quote token
  rxResult = await wrappedSynthetixAdapter.sellQuote(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address","address","address"],
        [Quote.address,Base.address,wrapper]
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

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for synthetix_etherwrapper(eth)
async function execute() {

  //compared tx
  //https://etherscan.io/tx/0xa08515a2a1cb0832e535d45403ebec2f38e4485140fd2d4b91f8e2360768a762

  // Network 
  await setForkNetWorkAndBlockNumber('eth',18133086);

  const tokenConfig = getConfig("eth");

  
  const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);
  await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

  Base = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  Quote = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.sETH.baseTokenAddress
  )
  
  SynthetixEtherWrapperAdapter = await ethers.getContractFactory("SynthetixEtherWrapperAdapter");
  synthetixEtherWrapperAdapter = await SynthetixEtherWrapperAdapter.deploy();
  await synthetixEtherWrapperAdapter.deployed();

  const poolAddr = "0x0000000000000000000000000000000000000000";

  console.log("before Base Balance: " + await Base.balanceOf(account.address));
  console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

  // // transfer 0.0004wETH to adapter
  // await Base.connect(account).transfer(synthetixEtherWrapperAdapter.address, ethers.utils.parseUnits('0.0004',tokenConfig.tokens.WETH.decimals));

  // // sell base token 
  // rxResult = await synthetixEtherWrapperAdapter.sellBase(
  //     account.address,                                // receive token address
  //     poolAddr,                                       // Pool
  //     ethers.utils.defaultAbiCoder.encode(
  //       ["bool"],
  //       [true]
  //     )
  // );

  // console.log("after Base Balance: " + await Base.balanceOf(account.address));
  // console.log("after Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 0.0004 sETH to adapter
  await Quote.connect(account).transfer(synthetixEtherWrapperAdapter.address, ethers.utils.parseUnits('0.0004',tokenConfig.tokens.sETH.decimals));      
  
  // sell quote token
  rxResult = await synthetixEtherWrapperAdapter.sellQuote(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["bool"],
        [false]
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

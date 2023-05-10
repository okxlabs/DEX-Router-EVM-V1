const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for rocketpool(eth)
async function execute() {

  // Network ETH
  await setForkNetWorkAndBlockNumber('eth',17191559);

  const tokenConfig = getConfig("eth");

  
  const accountAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";//vitalik.eth
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  Base = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  Quote = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.rETH.baseTokenAddress
  )

  const DEPOSITPOOL = "0xDD3f50F8A6CafbE9b31a427582963f465E745AF8";
  RocketpoolAdapter = await ethers.getContractFactory("RocketpoolAdapter");
  rocketpoolAdapter = await RocketpoolAdapter.deploy(Quote.address,DEPOSITPOOL,Base.address);
  await rocketpoolAdapter.deployed();

  const poolAddr = "0xDD3f50F8A6CafbE9b31a427582963f465E745AF8";//depositpool

  console.log("before Base Balance: " + await Base.balanceOf(account.address));
  console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 0.2 WETH to adapter
  await Base.connect(account).transfer(rocketpoolAdapter.address, ethers.utils.parseEther('0.02'));

  // sell base token 
  rxResult = await rocketpoolAdapter.sellBase(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["bool"],
        [true]
      )
  );

  console.log("after Base Balance: " + await Base.balanceOf(account.address));
  console.log("after Quote Balance: " + await Quote.balanceOf(account.address));

  // transfer 1 rETH to adapter
    await Quote.connect(account).transfer(rocketpoolAdapter.address, ethers.utils.parseUnits('0.01',tokenConfig.tokens.rETH.decimals));

  // sell quote token
  rxResult = await rocketpoolAdapter.sellQuote(
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

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for eth
async function execute() {
    // Compare TX
    // https://etherscan.io/tx/0x96af3882334be2039c01de273249c3fb9af5225e6fc782fba3569ed13ce31b29 USDC-USDT
    // Compare TX
    // https://arbiscan.io/tx/0x2924ab28c30fa2931bd30ac46ba979a5bb5e0edb8ac8584bd3c67feebe83ae91

    // Network eth
    await setForkNetWorkAndBlockNumber('eth', 17272038);
    // Network arbitrum 
    // await setForkNetWorkAndBlockNumber('arbitrum',89457086);

    const tokenConfig = getConfig("eth");
    // const tokenConfig = getConfig("arbitrum");
     
    const accountAddress = "0xde1820f69b3022b8c3233d512993eba8cff29ebb";//eth
    //const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    await setBalance(accountAddress, "0x53444835ec58000000");

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
      //tokenConfig.tokens.WETH.baseTokenAddress
    )
    
    console.log("Native token balance before deploying: " + await account.getBalance());

    SingleTestAdapter = await ethers.getContractFactory("IntegralAdapter");
    singleTestAdapter = await SingleTestAdapter.connect(account).deploy("0xd17b3c9784510E33cD5B87b490E79253BcD81e2E");//eth
    //singleTestAdapter = await SingleTestAdapter.deploy("");//arb
    await singleTestAdapter.deployed();

    const poolAddr = "0x6ec472b613012a492693697FA551420E60567eA7";//eth USDC-USDT 5,099.819818 USDC
    //const poolAddr = "0x4bca34ad27df83566016b55c60dd80a9eb14913b";//arb WETH-USDC 1USDC

    console.log("Native token balance before tx: " + await account.getBalance())
    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    

    // transfer 5,099.819818 USDC to adapter
    await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('5099.819818',tokenConfig.tokens.USDC.decimals));
    // transfer 1 USDC to adapter
    //await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));
    

    //Related parameters
    const amountIn = ethers.utils.parseUnits('5099.819818',tokenConfig.tokens.USDC.decimals);
    const amountOutMin = 0;
    //const gasLimit = 500000;
    const submitDeadline = 2000000000;
    // sell base token 
    rxResult = await singleTestAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        ethers.utils.defaultAbiCoder.encode(
          ["address", "address", "uint256", "uint32"],
          [Base.address, Quote.address, amountOutMin, submitDeadline]
        )
    );
  
    console.log("Native token balance after tx: " + await account.getBalance())
    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
        
    console.log("Native token spent by tx: " + await getTransactionCost(rxResult));

    // transfer 1 USDT to adapter 
    // await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));
    // transfer 5219.267515 USDT to adapter 
    await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('5219.267515',tokenConfig.tokens.USDT.decimals));
        
    const amountIn2 = ethers.utils.parseUnits('5099.819818',tokenConfig.tokens.USDT.decimals);
    // sell quote token
    rxResult = await singleTestAdapter.sellQuote(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256", "uint32"],
        [Quote.address, Base.address, amountOutMin, submitDeadline]
      )
  );
    
    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
}

const getTransactionCost = async (txResult) => {
  const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
  return ethers.BigNumber.from(txResult.gasPrice).mul(ethers.BigNumber.from(cumulativeGasUsed));
};

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for eth
async function execute() {

    // Compare TX
    // https://arbiscan.io/tx/0x428e281f92b5b5245276b126f6ecc5d86a81918f5b20d9fec6ceb71e69382035


    // Network arbitrum 
    await setForkNetWorkAndBlockNumber('arbitrum',94563814);

    const tokenConfig = getConfig("arbitrum");
     
    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    //await setBalance(accountAddress, "0x53444835ec58000000");

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )
    
    console.log("Native token balance before deploying: " + await account.getBalance());

    SingleTestAdapter = await ethers.getContractFactory("TraderJoeV2P1Adapter");
    singleTestAdapter = await SingleTestAdapter.connect(account).deploy();//arb
    await singleTestAdapter.deployed();

    const poolAddr = "0x0242DD3b2e792CdBD399cc6195951bC202Aee97B";//arb USDT-USDC 1USDC

    console.log("Native token balance before tx: " + await account.getBalance())
    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    console.log(" =================== traderJoeUSDC2USDT ===================")


    // transfer 1 USDC to pool
    await Base.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));
    // transfer 1 USDC to adapter
    //await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

    //Related parameters

    // sell base token 
    rxResult = await singleTestAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        "0x"
    );
  
    console.log("Native token balance after tx: " + await account.getBalance())
    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
        
    console.log("Native token spent by tx: " + await getTransactionCost(rxResult));
    console.log(" =================== traderJoeUSDT2USDC ===================")

    // transfer 1 USDT to pool
    await Quote.connect(account).transfer(poolAddr , ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));
    // transfer 1 to adapter 
    // await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));
        
    // sell quote token
    rxResult = await singleTestAdapter.sellQuote(
      account.address,                                // receive token address
      poolAddr,                                       // Pool
      "0x"
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

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
// need to change compare Tx、Network、Base and Quote、adapter、poolAddr、transfer token、moreinfo、 rxResult

async function execute() {
    // Compare TX：dopple
    // https://bscscan.com/tx/0xec7c09bac2598d6c8f3edd151cde27dda88dcff8552450c525c2958d43569099

    // Network bsc
    await setForkNetWorkAndBlockNumber('bsc',27621131);

    // Network bsc
    const tokenConfig = getConfig("bsc");
     
    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.DAI.baseTokenAddress
    )

    //adapter
    console.log("===== Adapter =====");
    SingleTestAdapter = await ethers.getContractFactory("DoppleAdapter");
    singleTestAdapter = await SingleTestAdapter.deploy();
    await singleTestAdapter.deployed();

    const poolAddr = "0x5162f992EDF7101637446ecCcD5943A9dcC63A8A";//dopple（bsc）USDT-USDC-BUSD-DAI 1USDT=>dai

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellQuote ==================");
    // transfer 1 USDT to poolAddr
    // await Base.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));
    // transfer 1 USDT to adapter
    await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));

    //moreinfo1
    const FOREVER = '2000000000';//this adapter need deadline
    const BaseIndex = '2';//this adapter need index of token address
    const QuoteIndex = '0';
    const moreinfo1 = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "address", "uint8", "uint8"],
      [FOREVER, Base.address, Quote.address, BaseIndex, QuoteIndex]
    )

    // sell base token 
    rxResult = await singleTestAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        moreinfo1
    );

    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellBase ==================");
    // transfer 1 DAI to poolAddr
    // await Quote.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.DAI.decimals));
    // transfer 1 USDT to adapter
    await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.DAI.decimals));

    //moreinfo2
    const moreinfo2 = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "address", "uint8", "uint8"],
      [FOREVER, Quote.address, Base.address, QuoteIndex, BaseIndex]
    )

    // sell quote token
    rxResult = await singleTestAdapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        moreinfo2
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

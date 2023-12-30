const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
// need to change compare Tx、Network、Base and Quote、adapter、poolAddr、transfer token、moreinfo、 rxResult

async function execute() {
    // Compare TX：kwenta
    // https://optimistic.etherscan.io/tx/0x5ae9714ab43a503a99e3c8794692e0baab4a44ef5f325d2ce6fb9c39e910ba64

    // Network op
    await setForkNetWorkAndBlockNumber('op',109408590);


    // Network op
    const tokenConfig = getConfig("op");

     
    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.sUSD.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.sETH.baseTokenAddress
    )

    //adapter
    //const snxproxyAddr = "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F";//eth
    const snxproxyAddr = "0x8700dAec35aF8Ff88c16BdF0418774CB3D7599B4";//op
    console.log("===== Adapter =====");
    SingleTestAdapter = await ethers.getContractFactory("SynthetixExchangeWithTrackingAdapter");
    singleTestAdapter = await SingleTestAdapter.deploy(snxproxyAddr);
    await singleTestAdapter.deployed();

    const poolAddr = "0x0000000000000000000000000000000000000000";//1sUSD-1sETH

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellBase ==================");
    // transfer 1 sUSD to adapter
    await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('0.997',tokenConfig.tokens.sUSD.decimals));

    //moreinfo1
    const sourceCurrencyKey = '0x7355534400000000000000000000000000000000000000000000000000000000';//sUSD
    const destinationCurrencyKey = '0x7345544800000000000000000000000000000000000000000000000000000000';//sETH
    const moreinfo1 = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes32", "address", "address"],
      [sourceCurrencyKey, destinationCurrencyKey, Base.address, Quote.address]
    )

    // sell base token 
    rxResult = await singleTestAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        moreinfo1
    );

    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellQuote ==================");
    // transfer 1 sETH to adapter
    await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('0.001',tokenConfig.tokens.sETH.decimals));

    //moreinfo2
    const moreinfo2 = ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes32", "address", "address"],
      [destinationCurrencyKey, sourceCurrencyKey, Quote.address, Base.address]
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

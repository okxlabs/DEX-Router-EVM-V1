const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
// need to change compare Tx、Network、Base and Quote、adapter、poolAddr、transfer token、moreinfo、 rxResult

async function execute() {
    // Compare TX：xfai
    // 

    // Network eth
    await setForkNetWorkAndBlockNumber('eth',17976090);

    // Network eth
    const tokenConfig = getConfig("eth");
     
    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    await setBalance(accountAddress, "0x1bc16d674ec80000"); // 2 eth

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.xfETH.baseTokenAddress
    )

    //adapter
    console.log("===== Adapter =====");
    SingleTestAdapter = await ethers.getContractFactory("XfaiAdapter");
    singleTestAdapter = await SingleTestAdapter.deploy();
    await singleTestAdapter.deployed();

    const poolAddr = "0x1d2e5a754A356d4D9B6a9D79378F9784c0c9aAC0";//usdc-xfETH

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellBase ==================");
    // transfer 1 USDC to poolAddr
    await Base.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));


    //moreinfo1

    const moreinfo1 = ethers.utils.defaultAbiCoder.encode(
      [ "address"],
      [Base.address]
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
    // transfer xfETH to poolAddr
    await Quote.connect(account).transfer(poolAddr, ethers.utils.parseUnits('0.000584057149453704',tokenConfig.tokens.xfETH.decimals));


    //moreinfo2
    const moreinfo2 = moreinfo1;

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

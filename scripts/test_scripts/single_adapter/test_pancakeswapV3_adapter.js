const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
// need to change compare Tx、Network、Base and Quote、adapter、poolAddr、transfer token、moreinfo、 rxResult

async function execute() {
    // Compare TX：pancakeswapV3(bsc)
    // https://bscscan.com/tx/0x40a5042a0b2ea7b738dc7317661dff8c850189c306c55afbd6b3186c6bb74b87
    // Compare TX：pancakeswapV3(eth)
    // https://etherscan.io/tx/0xc3dc432f2d6613afbd987ba2cad4489538f48f73837ad255aa0fa89ab8a6ca78

    // Network bsc
    //await setForkNetWorkAndBlockNumber('bsc',27674307);
    // Network eth
    await setForkNetWorkAndBlockNumber('eth',17127458);

    // Network bsc
    //const tokenConfig = getConfig("bsc");
    // Network eth
    const tokenConfig = getConfig("eth");

     
    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x53444835ec58000000");

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )

    //adapter
    console.log("===== Adapter =====");
    const factoryAddr = "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865";// pancake factoryAddress on bsc and eth
    SingleTestAdapter = await ethers.getContractFactory("PancakeswapV3Adapter");
    singleTestAdapter = await SingleTestAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress,factoryAddr);// WETH/WBNB
    await singleTestAdapter.deployed();

    //const poolAddr = "0x92b7807bF19b7DDdf89b706143896d05228f3121";//pancakeswapV3（bsc）USDT-USDC 1USDT=>USDC
    const poolAddr = "0x04c8577958CcC170EB3d2CCa76F9d51bc6E42D8f";//pancakeswapV3（eth）USDT-USDC 1USDT=>USDC

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellQuote ==================");
    // transfer 1 USDT to poolAddr
    // await Base.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));
    // transfer 1 USDT to adapter
    await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));

    //moreinfo1
    const moreinfo1 = ethers.utils.defaultAbiCoder.encode(
      ["uint160", "bytes"],
      [
        // "888971540474059905480051",
        0,
        ethers.utils.defaultAbiCoder.encode(
          ["address", "address", "uint24"],
          [
            Base.address,
            Quote.address,
            100,
          ]
        )
      ]
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
    await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

    //moreinfo2
    const moreinfo2 = ethers.utils.defaultAbiCoder.encode(
      ["uint160", "bytes"],
      [
        // "888971540474059905480051",
        0,
        ethers.utils.defaultAbiCoder.encode(
          ["address", "address","uint24"],
          [
            Quote.address,
            Base.address,
            100,
          ]
        )
      ]
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

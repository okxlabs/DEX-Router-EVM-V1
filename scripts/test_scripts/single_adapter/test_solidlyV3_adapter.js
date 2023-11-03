const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
// need to change compare Tx、Network、Base and Quote、adapter、poolAddr、transfer token、moreinfo、 rxResult

async function execute() {
    // Compare TX：eth
    // https://etherscan.io/tx/0x03f4f4fe36d0a764fe9bf531fdfbe20c1a88b10a5df04f37e63a55c9bd747d33

    // Network eth
    await setForkNetWorkAndBlockNumber('eth',18304515);

    // Network eth
    const tokenConfig = getConfig("eth");

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    await setBalance(accountAddress, "0x53444835ec58000000");

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress
    )

    //adapter
    console.log("===== Adapter =====");
    //const factoryAddr = "0x735BB16affe83A3DC4dC418aBCcF179617Cf9FF2";// solidlyv3 factoryAddress on eth
    SingleTestAdapter = await ethers.getContractFactory("SolidlyV3Adapter");
    singleTestAdapter = await SingleTestAdapter.deploy();
    await singleTestAdapter.deployed();

    const poolAddr = "0xaFED85453681dc387EE0E87b542614722EE2CfeD";//solidlyV3（eth）USDC-WETH 1USDC=>WETH

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));
    
    console.log("\n================== SellQuote ==================");
    // transfer 1 USDT to poolAddr
    // await Base.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));
    // transfer 1 USDC to adapter
    await Base.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

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
    // transfer 1 WETH to adapter
    await Quote.connect(account).transfer(singleTestAdapter.address, ethers.utils.parseUnits('0.001',tokenConfig.tokens.WETH.decimals));

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

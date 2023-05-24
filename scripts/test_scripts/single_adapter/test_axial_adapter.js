const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for spiritswapv2（ftm）、cone（bsc）、Dystopia（poly）、Velodrome（op）、Rames Exchanges（arb）、solidlizard（arb）
async function execute() {
    // Compare TX：
    // https://snowtrace.io/tx/0xf3da55bf95adae7ef6ef12f4042dd5ee781ecf9640027ad76300014f8ac9fae8

    // Network Avax
    await setForkNetWorkAndBlockNumber('avax',30371930);

    const tokenConfig = getConfig("avax");

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    AxialAdapter = await ethers.getContractFactory("AxialAdapter");
    axialAdapter = await AxialAdapter.deploy();
    await axialAdapter.deployed();

    const poolAddr = "0xa0f6397FEBB03021F9BeF25134DE79835a24D76e";// USDC-USDt 0.1USDC

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

    // transfer 0.1 USDC to adapter
    await Base.connect(account).transfer(axialAdapter.address, ethers.utils.parseUnits('0.1',tokenConfig.tokens.USDC.decimals));


    //moreinfo1
    const FOREVER = '2000000000';//this adapter need deadline
    const BaseIndex = '0';//this adapter need index of token address
    const QuoteIndex = '1';
    const moreinfo1 = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "address", "uint8", "uint8"],
      [FOREVER, Base.address, Quote.address, BaseIndex, QuoteIndex]
    )
    
    // sell base token 
    rxResult = await  axialAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        moreinfo1
    );

    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));


    // transfer 0.1 USDT to adapter
    await Quote.connect(account).transfer(axialAdapter.address, ethers.utils.parseUnits('0.1',tokenConfig.tokens.USDT.decimals));


    //moreinfo2
    const moreinfo2 = ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address", "address", "uint8", "uint8"],
      [FOREVER, Quote.address, Base.address, QuoteIndex, BaseIndex]
    )

    // sell quote token
    rxResult = await axialAdapter.sellQuote(
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

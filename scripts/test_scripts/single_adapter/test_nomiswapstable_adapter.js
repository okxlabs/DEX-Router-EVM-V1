const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
    // Compare TX
    // https://cn.etherscan.com/tx/0x64a48e25fd9a664dce496f5e804002b980a414f6f2ef2b00928abce78275afc9

    // Network Main
    await setForkBlockNumber(16668912);

    const tokenConfig = getConfig("eth");

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    await setBalance(accountAddress, "0x53444835ec58000000");

    USDT = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )
    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )

    NomiswapStable = await ethers.getContractFactory("NomiswapAdapter");
    nomiswapAdapter = await NomiswapStable.deploy("0xEfD2f571989619a942Dc3b5Af63866B57D1869ED", "0x818339b4E536E707f14980219037c5046b049dD4");//(address _NomiswapFactory, address _NomiswapStableFactory) 
    await nomiswapAdapter.deployed();

    const poolAddr = "0x9Daeb0A1849D57f6BEBe0e5969644950f0689936";//address of DAI-USDT pair in NomiswapStableFactory

    console.log("before USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before DAI Balance: " + await DAI.balanceOf(account.address));

    // transfer 1DAI to poolAddr
    
    await DAI.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',18));

    // DAI to USDT token pool
    rxResult = await nomiswapAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // DAI-USDT Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));

    // transfer 1U to poolAddr
    await USDT.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',6));

    // USDT to DAI token pool
    rxResult = await nomiswapAdapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // USDT-DAI Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
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

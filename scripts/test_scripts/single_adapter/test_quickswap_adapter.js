const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
    // Compare TX
    // https://polygonscan.com/tx/0xa7ab57222f1a4425c37ef921cff92847ef1c7bf8b0de6b3f059df9533e80a989

    // Network Polygon
    await setForkNetWorkAndBlockNumber('polygon',40528787);

    const tokenConfig = getConfig("polygon");

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WMATIC = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WMATIC.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )

    QuickswapAdapter = await ethers.getContractFactory("QuickswapAdapter");
    quickswapAdapter = await QuickswapAdapter.deploy();
    await quickswapAdapter.deployed();

    const poolAddr = "0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827";

    console.log("before WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 1 WMATIC to poolAddr
    
    await WMATIC.connect(account).transfer(poolAddr, ethers.utils.parseEther('1'));

    // WMATIC to USDC token pool
    rxResult = await quickswapAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // WMATIC-USDC Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 1 USDC to poolAddr
    await USDC.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

    // USDC to WMATIC token pool
    rxResult = await quickswapAdapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // WMATIC-USDC Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
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

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
    // Compare TX
    // https://polygonscan.com/tx/0x53613502c2d11de7ff9f31d248c6893882de62092f0820495a690a63df3e81f1

    // Network Polygon
    await setForkNetWorkAndBlockNumber('polygon',40604682);

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

    Quickswapv3Adapter = await ethers.getContractFactory("Quickswapv3Adapter");
    quickswapv3Adapter = await Quickswapv3Adapter.deploy(tokenConfig.tokens.WMATIC.baseTokenAddress);
    await quickswapv3Adapter.deployed();

    const poolAddr = "0xAE81FAc689A1b4b1e06e7ef4a2ab4CD8aC0A087D"; //quickswapv3 WMATIC-USDC pool

    console.log("before WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 1 WMATIC to poolAddr
    
    await WMATIC.connect(account).transfer(quickswapv3Adapter.address, ethers.utils.parseEther('1'));

    // WMATIC to USDC token pool
    rxResult = await quickswapv3Adapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // WMATIC-USDC Pool
        ethers.utils.defaultAbiCoder.encode(
          ["uint160", "bytes"],
          [
            // "888971540474059905480051",
            0,
            ethers.utils.defaultAbiCoder.encode(
              ["address", "address"],
              [
                WMATIC.address,
                USDC.address,
              ]
            )
          ]
        )
    );
    // console.log(rxResult);

    console.log("after WMATIC Balance: " + await WMATIC.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 1 USDC to poolAddr
    await USDC.connect(account).transfer(quickswapv3Adapter.address, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

    // USDC to WMATIC token pool
    rxResult = await quickswapv3Adapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // WMATIC-USDC Pool
        ethers.utils.defaultAbiCoder.encode(
          ["uint160", "bytes"],
          [
            // "888971540474059905480051",
            0,
            ethers.utils.defaultAbiCoder.encode(
              ["address", "address"],
              [
                USDC.address,
                WMATIC.address,
              ]
            )
          ]
        )
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

const { ethers } = require("hardhat");
require("./tools");
const { getConfig } = require("./config");
tokenConfig = getConfig("eth");

async function execute() {
    // Compare TX
    // https://cn.etherscan.com/tx/0x64a48e25fd9a664dce496f5e804002b980a414f6f2ef2b00928abce78275afc9

    // Network Main
    await setForkBlockNumber(14446603);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WETH = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress
    )
    RND = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.RND.baseTokenAddress
    )

    UniV2Adapter = await ethers.getContractFactory("UniAdapter");
    univ2Adapter = await UniV2Adapter.deploy();
    await univ2Adapter.deployed();

    const poolAddr = "0x5449bd1a97296125252db2d9cf23d5d6e30ca3c1";

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // transfer 0.0625 WETH to poolAddr
    
    await WETH.connect(account).transfer(poolAddr, ethers.utils.parseEther('100'));

    // WETH to RND token pool
    rxResult = await univ2Adapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // WETH-RND Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after RND Balance: " + await RND.balanceOf(account.address));

    // transfer 462571280 RND to poolAddr
    await RND.connect(account).transfer(poolAddr, ethers.utils.parseEther('16306887544.577753070502043886'));

    // USDT to WETH token pool
    rxResult = await univ2Adapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // WETH-RND Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after RND Balance: " + await RND.balanceOf(account.address));
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

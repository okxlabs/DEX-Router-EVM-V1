const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
    // Compare TX
    // https://arbiscan.io/tx/0xea5a84dd74013f6c657e08d5a809e98b51bbf0679328cb3198eaefd58b0e0149
    // Network arb
    await setForkNetWorkAndBlockNumber('artibrum', 103381652);

    const tokenConfig = getConfig("arbitrum");

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    USDT = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    hUSDT = await ethers.getContractAt(
      "MockERC20",
      "0x12e59C59D282D2C00f3166915BED6DC2F5e2B5C7"
    )

    HtokenAdapter = await ethers.getContractFactory("HtokenAdapter");
    HtokenAdapter = await HtokenAdapter.deploy();
    await HtokenAdapter.deployed();
    
    await hUSDT.connect(account).transfer(HtokenAdapter.address, ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals));

    const poolAddr = "0x18f7402B673Ba6Fb5EA4B95768aABb8aaD7ef18a";

    console.log("before hUSDT Balance: " + await hUSDT.balanceOf(account.address));
    console.log("before USDT Balance: " + await USDT.balanceOf(account.address));
    const amount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);

    const moreInfo = ethers.utils.defaultAbiCoder.encode(["address", "address"],["0x12e59C59D282D2C00f3166915BED6DC2F5e2B5C7", tokenConfig.tokens.USDT.baseTokenAddress]);
    // hUSDT to USDT token pool
    rxResult = await HtokenAdapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // hUSDT-USDT Pool
        moreInfo
    );
    console.log(rxResult);

    console.log("after hUSDT Balance: " + await hUSDT.balanceOf(account.address));
    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
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

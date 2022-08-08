
const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
tokenConfig = getConfig("eth");

async function deployContract() {
    ShellAdapter = await ethers.getContractFactory("ShellAdapter");
    ShellAdapter = await ShellAdapter.deploy();
    await ShellAdapter.deployed();
    return ShellAdapter
}

// 0x8f26D7bAB7a73309141A291525C965EcdEa7Bf42
// https://etherscan.io/tx/0xd8eb9fac56eb397f0d9fec81a69edc03fe161a58fb05275d4eeeabfb4dace55a
async function executeUsdPool(ShellAdapter) {
    userAddress = "0xda8A87b7027A6C235f88fe0Be9e34Afd439570b5"
    poolAddress = "0x8f26D7bAB7a73309141A291525C965EcdEa7Bf42"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    // DAI
    DaiContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.DAI.baseTokenAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(userAddress);
    console.log("user balance: ", beforeBalance.toString());

    // transfer token
    await USDTContract.connect(signer).transfer(ShellAdapter.address, ethers.utils.parseUnits("6000", 6));
    afterBalance = await USDTContract.balanceOf(ShellAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(ShellAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    const DDL = 2541837122
    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256"],
      [
          USDTContract.address,
          DaiContract.address,
          DDL
      ]
    )
    rxResult = await ShellAdapter.sellQuote(
        ShellAdapter.address,
        poolAddress,
        moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(ShellAdapter.address);
    usdtBalance = await USDTContract.balanceOf(ShellAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());
}


// 0xC2D019b901f8D4fdb2B9a65b5d226Ad88c66EE8D
// https://etherscan.io/tx/0x111fd52e3af071b8db796ba1c6f5992cc80b66cdbc61c81164c0a963384b4717
async function executeBTCPool(ShellAdapter) {
  userAddress = "0x593c427d8C7bf5C555Ed41cd7CB7cCe8C9F15bB5"
  poolAddress = "0xC2D019b901f8D4fdb2B9a65b5d226Ad88c66EE8D"

  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // USDT
  WBTC = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WBTC.baseTokenAddress
  )

  // DAI
  renBTC = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.renBTC.baseTokenAddress
  )

  await WBTC.connect(signer).transfer(ShellAdapter.address, ethers.utils.parseUnits("1", tokenConfig.tokens.WBTC.decimals));

  // check user token
  beforeBalance = await WBTC.balanceOf(ShellAdapter.address);
  console.log("WBTC beforebalance: ", beforeBalance.toString());

  // swap
  beforeBalance = await renBTC.balanceOf(ShellAdapter.address);
  console.log("renBTC beforeBalance: ", beforeBalance.toString());


  const DDL = 2541837122
  moreinfo =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
        WBTC.address,
        renBTC.address,
        DDL
    ]
  )
  rxResult = await ShellAdapter.sellQuote(
    ShellAdapter.address,
    poolAddress,
    moreinfo
  );

  // console.log(rxResult)

  wbtcBalance = await WBTC.balanceOf(ShellAdapter.address);
  renBTCBalance = await renBTC.balanceOf(ShellAdapter.address);
  console.log("WBTC afterBalance: ", wbtcBalance.toString());
  console.log("renBTC afterBalance: ", renBTCBalance.toString());
}


async function main() {
    ShellAdapter = await deployContract()
    console.log("===== check usd Pool =====")
    await executeUsdPool(ShellAdapter);
    console.log("===== check btc Pool =====")
    await executeBTCPool(ShellAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });



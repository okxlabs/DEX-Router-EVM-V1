const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
  // Compare TX
  // https://bscscan.com/tx/0x3c307eede3a0ceab6c49511415ed3cd8c1d265a751b32f95bf1963a3f4bd6d55
  // Network Main
  await setForkNetWorkAndBlockNumber("bsc", 26652695);

  const tokenConfig = getConfig("bsc");

  const accountAddress = "0x4cf3b52fb87d971dae37247f0cc7c64110c6ba7c";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  USDT = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDT.baseTokenAddress
  );

  USDC = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDC.baseTokenAddress
  );

  PancakeAdapter = await ethers.getContractFactory("PancakestableAdapter");
  pancakeAdapter = await PancakeAdapter.deploy();
  await pancakeAdapter.deployed();

  const poolAddr = "0x3EFebC418efB585248A0D2140cfb87aFcc2C63DD";

  console.log(
    "before USDC Balance: " + (await USDC.balanceOf(account.address))
  );
  console.log(
    "before USDT Balance: " + (await USDT.balanceOf(account.address))
  );

  await USDC.connect(account).transfer(
    pancakeAdapter.address,
    ethers.utils.parseUnits("505", 18)
  );
  moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128"],
    [USDC.address, USDT.address, 1, 0]
  );

  rxResult = await pancakeAdapter.sellQuote(
    account.address,
    poolAddr,
    moreinfo
  );

  console.log("after USDC Balance: " + (await USDC.balanceOf(account.address)));
  console.log("after USDT Balance: " + (await USDT.balanceOf(account.address)));
  console.log(
    "after pcs Balance: " + (await USDC.balanceOf(pancakeAdapter.address))
  );

  await USDT.connect(account).transfer(
    pancakeAdapter.address,
    ethers.utils.parseUnits("503.169228095900770213", 18)
  );
  moreinfo1 = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128"],
    [USDT.address, USDC.address, 0, 1]
  );

  rxResult = await pancakeAdapter.sellBase(
    account.address,
    poolAddr,
    moreinfo1
  );

  console.log("after USDC Balance: " + (await USDC.balanceOf(account.address)));
  console.log("after USDT Balance: " + (await USDT.balanceOf(account.address)));
}

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

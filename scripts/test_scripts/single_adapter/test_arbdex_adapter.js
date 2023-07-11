const { ethers } = require("hardhat");
require("../../tools");

const pair1_address = "0xD082d6E0AF69f74F283b90C3CDa9C35615Bce367"; // USDT-USDC.e

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 107330150);

  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let arbDexAdapter = await ethers.getContractFactory("ArbDexAdapter");
  let ArbDexAdapter = await arbDexAdapter.connect(depolyer).deploy();
  await ArbDexAdapter.connect(depolyer).deployed();

  let IArbDexPair = await ethers.getContractAt("IArbDexPair", pair1_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  let [token0, token1] = [
    await IArbDexPair.token0(),
    await IArbDexPair.token1(),
  ];
  // USDT
  let USDTContract = await ethers.getContractAt("MockERC20", token0);
  // USDC
  let USDCContract = await ethers.getContractAt("MockERC20", token1);

  // check user token
  console.log(
    await USDTContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
    )
  );
  console.log(
    await USDCContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await USDCContract.balanceOf(userAddress),
      await USDCContract.decimals()
    )
  );

  // 1. swap USDC -> USDT
  await USDCContract.connect(signer).transfer(
    pair1_address,
    ethers.utils.parseUnits("2000", await USDCContract.decimals())
  );
  let moreinfo = ethers.utils.defaultAbiCoder.encode([], []);
  await ArbDexAdapter.sellQuote(userAddress, pair1_address, moreinfo);

  // the result of first swap
  console.log(
    "1st swap:",
    await USDTContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
    )
  );
  console.log(
    "1st swap:",
    await USDCContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDCContract.balanceOf(userAddress),
      await USDCContract.decimals()
    )
  );

  // 2. swap USDT -> USDC
  await USDTContract.connect(signer).transfer(
    pair1_address,
    ethers.utils.parseUnits("1000", await USDTContract.decimals())
  );
  await ArbDexAdapter.sellBase(userAddress, pair1_address, moreinfo);

  // the result of second swap
  console.log(
    "2nd swap:",
    await USDTContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
    )
  );
  console.log(
    "2nd swap:",
    await USDCContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDCContract.balanceOf(userAddress),
      await USDCContract.decimals()
    )
  );
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

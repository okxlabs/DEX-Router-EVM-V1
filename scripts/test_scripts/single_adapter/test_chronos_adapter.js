const { ethers } = require("hardhat");
require("../../tools");

const pair1_address = "0x8a263Cc1DfDCe6c64e2A1cf6133c22eED5D4E29d"; // WETH-USDT

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 100283960);

  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let chronosAdapter = await ethers.getContractFactory("ChronosAdapter");
  let ChronosAdapter = await chronosAdapter.connect(depolyer).deploy();
  await ChronosAdapter.connect(depolyer).deployed();

  let IChronosPair = await ethers.getContractAt("IChronosPair", pair1_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  let [token0, token1] = [
    await IChronosPair.token0(),
    await IChronosPair.token1(),
  ];
  // WETH
  let WETHContract = await ethers.getContractAt("MockERC20", token0);
  // USDT
  let USDTContract = await ethers.getContractAt("MockERC20", token1);

  // check user token
  console.log(
    await WETHContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await WETHContract.balanceOf(userAddress),
      await WETHContract.decimals()
    )
  );
  console.log(
    await USDTContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
    )
  );

  // 1. swap USDT -> WETH
  await USDTContract.connect(signer).transfer(
    pair1_address,
    ethers.utils.parseUnits("2000", await USDTContract.decimals())
  );
  let moreinfo = ethers.utils.defaultAbiCoder.encode([], []);
  await ChronosAdapter.sellQuote(userAddress, pair1_address, moreinfo);

  // the result of first swap
  console.log(
    "1st swap:",
    await WETHContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await WETHContract.balanceOf(userAddress),
      await WETHContract.decimals()
    )
  );
  console.log(
    "1st swap:",
    await USDTContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
    )
  );

  // 2. swap WETH -> USDT
  let wethBalance = await WETHContract.balanceOf(userAddress);
  await WETHContract.connect(signer).transfer(
    pair1_address,
    wethBalance.div(2)
  );
  await ChronosAdapter.sellBase(userAddress, pair1_address, moreinfo);

  // the result of second swap
  console.log(
    "2nd swap:",
    await WETHContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await WETHContract.balanceOf(userAddress),
      await WETHContract.decimals()
    )
  );
  console.log(
    "2nd swap:",
    await USDTContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
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

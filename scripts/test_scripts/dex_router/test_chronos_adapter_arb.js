const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, FOREVER } = require("./utils");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arb");

const pair1_address = "0x8a263Cc1DfDCe6c64e2A1cf6133c22eED5D4E29d"; // WETH-USDT
const pair2_address = "0xC9445A9AFe8E48c71459aEdf956eD950e983eC5A"; // USDT-USDC

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 100283960);
  let { dexRouter, tokenApprove } = await initDexRouter(
    tokenConfig.tokens.WETH.baseTokenAddress
  );

  // deploy adapter, pair1, pair2
  [user1, depolyer] = await ethers.getSigners();
  let chronosAdapter = await ethers.getContractFactory("ChronosAdapter");
  let ChronosAdapter = await chronosAdapter.connect(depolyer).deploy();
  await ChronosAdapter.connect(depolyer).deployed();
  let IChronosPair1 = await ethers.getContractAt("IChronosPair", pair1_address);
  let IChronosPair2 = await ethers.getContractAt("IChronosPair", pair2_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  /*
   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start First Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   */
  let [token0, token1] = [
    await IChronosPair1.token0(),
    await IChronosPair1.token1(),
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

  // parameters about 2000 USDT -> WETH
  const fromTokenAmount = ethers.utils.parseUnits(
    "2000",
    await USDTContract.decimals()
  );
  const minReturnAmount = 0;
  const deadLine = FOREVER;
  let mixAdapter1 = [ChronosAdapter.address];
  let assetTo1 = [IChronosPair1.address];
  let weight1 = Number(10000).toString(16).replace("0x", "");
  let rawData1 = [
    "0x" +
      "8" + // 0: sellBase / 8: sellQuote
      "0000000000000000000" +
      weight1 +
      IChronosPair1.address.replace("0x", ""), // Pool
  ];
  let moreinfo = ethers.utils.defaultAbiCoder.encode([], []);
  let extraData1 = [moreinfo];
  let router1 = [
    mixAdapter1,
    assetTo1,
    rawData1,
    extraData1,
    USDTContract.address,
  ];
  let layer1 = [router1];
  let orderId = 0;
  let baseRequest = [
    USDTContract.address,
    WETHContract.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ];

  // tx
  await USDTContract.connect(signer).approve(
    tokenApprove.address,
    fromTokenAmount
  );
  await dexRouter.connect(signer).smartSwapByOrderId(
    orderId,
    baseRequest,
    [fromTokenAmount],
    [layer1],
    [] //pmmrequest
  );

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

  /*
   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start Second Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   */
  [token0, token1] = [
    await IChronosPair2.token0(),
    await IChronosPair2.token1(),
  ];
  // USDT
  USDTContract = await ethers.getContractAt("MockERC20", token0);
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

  // parameters about 2000 USDT -> USDC
  mixAdapter1 = [ChronosAdapter.address];
  assetTo1 = [IChronosPair2.address];
  rawData1 = [
    "0x" +
      "0" + // 0: sellBase / 8: sellQuote
      "0000000000000000000" +
      weight1 +
      IChronosPair2.address.replace("0x", ""), // Pool
  ];
  router1 = [mixAdapter1, assetTo1, rawData1, extraData1, USDTContract.address];
  layer1 = [router1];
  orderId = 1;
  baseRequest = [
    USDTContract.address,
    USDCContract.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ];

  // tx
  await USDTContract.connect(signer).approve(
    tokenApprove.address,
    fromTokenAmount
  );
  await dexRouter.connect(signer).smartSwapByOrderId(
    orderId,
    baseRequest,
    [fromTokenAmount],
    [layer1],
    [] //pmmrequest
  );

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

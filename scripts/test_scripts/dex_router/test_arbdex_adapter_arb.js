const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, FOREVER } = require("./utils");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arb");

const pair1_address = "0xD082d6E0AF69f74F283b90C3CDa9C35615Bce367"; // USDT-USDC.e
const pair2_address = "0xe14E08c43ceBd79f95D181543628C8EDe181bD02"; // CGLD-USDT

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 101451200);
  let { dexRouter, tokenApprove } = await initDexRouter(
    tokenConfig.tokens.WETH.baseTokenAddress
  );

  // deploy adapter, pair1, pair2
  [user1, depolyer] = await ethers.getSigners();
  let arbDexAdapter = await ethers.getContractFactory("ArbDexAdapter");
  let ArbDexAdapter = await arbDexAdapter.connect(depolyer).deploy();
  await ArbDexAdapter.connect(depolyer).deployed();
  let IArbDexPair1 = await ethers.getContractAt("IArbDexPair", pair1_address);
  let IArbDexPair2 = await ethers.getContractAt("IArbDexPair", pair2_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  /*
   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start First Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   */
  let [token0, token1] = [
    await IArbDexPair1.token0(),
    await IArbDexPair1.token1(),
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

  // parameters about 2000 USDT -> USDC
  let fromTokenAmount = ethers.utils.parseUnits(
    "2000",
    await USDTContract.decimals()
  );
  const minReturnAmount = 0;
  const deadLine = FOREVER;
  let mixAdapter1 = [ArbDexAdapter.address];
  let assetTo1 = [IArbDexPair1.address];
  let weight1 = Number(10000).toString(16).replace("0x", "");
  let rawData1 = [
    "0x" +
    "0" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    IArbDexPair1.address.replace("0x", ""), // Pool
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

  /*
   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start Second Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   */
  [token0, token1] = [
    await IArbDexPair2.token0(),
    await IArbDexPair2.token1(),
  ];
  // CGLD
  let CGLDContract = await ethers.getContractAt("MockERC20", token0);
  // USDT
  USDTContract = await ethers.getContractAt("MockERC20", token1);

  // check user token
  console.log(
    await CGLDContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await CGLDContract.balanceOf(userAddress),
      await CGLDContract.decimals()
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

  // parameters about 2000 USDT -> CGLD
  fromTokenAmount = ethers.utils.parseUnits(
    "2000",
    await USDTContract.decimals()
  );
  mixAdapter1 = [ArbDexAdapter.address];
  assetTo1 = [IArbDexPair2.address];
  rawData1 = [
    "0x" +
    "8" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    IArbDexPair2.address.replace("0x", ""), // Pool
  ];
  router1 = [mixAdapter1, assetTo1, rawData1, extraData1, USDTContract.address];
  layer1 = [router1];
  orderId = 1;
  baseRequest = [
    USDTContract.address,
    CGLDContract.address,
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
    await CGLDContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await CGLDContract.balanceOf(userAddress),
      await CGLDContract.decimals()
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

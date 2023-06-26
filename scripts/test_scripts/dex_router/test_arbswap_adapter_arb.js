const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, FOREVER } = require("./utils");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arb");

const pair1_address = "0x6E8AEE8Ed658fDCBbb7447743fdD98152B3453A0"; // WETH-USDC
const pair2_address = "0x4832e0a194281d1ffE464C654E4E938f642DD362"; // WETH-ARB

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 101451200);
  let { dexRouter, tokenApprove } = await initDexRouter(
    tokenConfig.tokens.WETH.baseTokenAddress
  );

  // deploy adapter, pair1, pair2
  [user1, depolyer] = await ethers.getSigners();
  let arbswapAdapter = await ethers.getContractFactory("ArbSwapAdapter");
  let ArbSwapAdapter = await arbswapAdapter.connect(depolyer).deploy();
  await ArbSwapAdapter.connect(depolyer).deployed();
  let IArbSwapPair1 = await ethers.getContractAt("IArbSwapPair", pair1_address);
  let IArbSwapPair2 = await ethers.getContractAt("IArbSwapPair", pair2_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  /*
   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start First Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   */
  let [token0, token1] = [
    await IArbSwapPair1.token0(),
    await IArbSwapPair1.token1(),
  ];
  // WETH
  let WETHContract = await ethers.getContractAt("MockERC20", token0);
  // USDC
  let USDCContract = await ethers.getContractAt("MockERC20", token1);

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
    await USDCContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await USDCContract.balanceOf(userAddress),
      await USDCContract.decimals()
    )
  );

  // parameters about 2000 USDC -> WETH
  let fromTokenAmount = ethers.utils.parseUnits(
    "2000",
    await USDCContract.decimals()
  );
  const minReturnAmount = 0;
  const deadLine = FOREVER;
  let mixAdapter1 = [ArbSwapAdapter.address];
  let assetTo1 = [IArbSwapPair1.address];
  let weight1 = Number(10000).toString(16).replace("0x", "");
  let rawData1 = [
    "0x" +
    "8" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    IArbSwapPair1.address.replace("0x", ""), // Pool
  ];
  let moreinfo = ethers.utils.defaultAbiCoder.encode([], []);
  let extraData1 = [moreinfo];
  let router1 = [
    mixAdapter1,
    assetTo1,
    rawData1,
    extraData1,
    USDCContract.address,
  ];
  let layer1 = [router1];
  let orderId = 0;
  let baseRequest = [
    USDCContract.address,
    WETHContract.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ];

  // tx
  await USDCContract.connect(signer).approve(
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
    await IArbSwapPair2.token0(),
    await IArbSwapPair2.token1(),
  ];
  // WETH
  WETHContract = await ethers.getContractAt("MockERC20", token0);
  // ARB
  let ARBContract = await ethers.getContractAt("MockERC20", token1);

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
    await ARBContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await ARBContract.balanceOf(userAddress),
      await ARBContract.decimals()
    )
  );

  // parameters about a half balance of WETH -> ARB
  let wethBalance = await WETHContract.balanceOf(userAddress);
  fromTokenAmount = wethBalance.div(2);
  mixAdapter1 = [ArbSwapAdapter.address];
  assetTo1 = [IArbSwapPair2.address];
  rawData1 = [
    "0x" +
    "0" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    IArbSwapPair2.address.replace("0x", ""), // Pool
  ];
  router1 = [mixAdapter1, assetTo1, rawData1, extraData1, WETHContract.address];
  layer1 = [router1];
  orderId = 1;
  baseRequest = [
    WETHContract.address,
    ARBContract.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ];

  // tx
  await WETHContract.connect(signer).approve(
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
    await WETHContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await WETHContract.balanceOf(userAddress),
      await WETHContract.decimals()
    )
  );
  console.log(
    "2nd swap:",
    await ARBContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await ARBContract.balanceOf(userAddress),
      await ARBContract.decimals()
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

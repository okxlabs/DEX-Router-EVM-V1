const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, FOREVER } = require("./utils");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arb");

const pair1_address = "0xE97Af01c48C0A332C06A92dF36b77B2A680AB54B"; // USDT-USDC stable
const pair2_address = "0xE7dE07F541EBeCcA39aB65CA2203bc54B7107353"; // wstETH-WETH stable

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 103064000);
  let { dexRouter, tokenApprove } = await initDexRouter(
    tokenConfig.tokens.WETH.baseTokenAddress
  );

  // deploy adapter, pair1, pair2
  [user1, depolyer] = await ethers.getSigners();
  let arbSwapV2Adapter = await ethers.getContractFactory("ArbSwapV2Adapter");
  let ArbSwapV2Adapter = await arbSwapV2Adapter.connect(depolyer).deploy();
  await ArbSwapV2Adapter.connect(depolyer).deployed();
  let IArbStableSwap1 = await ethers.getContractAt("IArbStableSwap", pair1_address);
  let IArbStableSwap2 = await ethers.getContractAt("IArbStableSwap", pair2_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  /*
   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start First Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
   */
  let [token0, token1] = [
    await IArbStableSwap1.coins(0),
    await IArbStableSwap1.coins(1),
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
  let mixAdapter1 = [ArbSwapV2Adapter.address];
  let assetTo1 = [ArbSwapV2Adapter.address];
  let weight1 = Number(10000).toString(16).replace("0x", "");
  let rawData1 = [
    "0x" +
    "8" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    IArbStableSwap1.address.replace("0x", ""), // Pool
  ];
  let info =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256", "uint256"],
    [
      USDTContract.address,
      USDCContract.address,
      0,
      1
    ]
  )
  let moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["uint8", "bytes"],
    [
      0, // stable swap
      info
    ]);
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
    await IArbStableSwap2.coins(0),
    await IArbStableSwap2.coins(1),
  ];
  // wstETH
  let wstETHContract = await ethers.getContractAt("MockERC20", token0);
  // WETH
  let WETHContract = await ethers.getContractAt("WETH9", token1);
  await WETHContract.connect(signer).deposit({ value: ethers.utils.parseUnits(
      "1",
      await WETHContract.decimals()
    )});

  // check user token
  console.log(
    await wstETHContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await wstETHContract.balanceOf(userAddress),
      await wstETHContract.decimals()
    )
  );
  console.log(
    await WETHContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await WETHContract.balanceOf(userAddress),
      await WETHContract.decimals()
    )
  );

  // parameters about 1 WETH -> wstETH
  fromTokenAmount = ethers.utils.parseUnits(
    "0.00001",
    await WETHContract.decimals()
  );
  mixAdapter1 = [ArbSwapV2Adapter.address];
  assetTo1 = [ArbSwapV2Adapter.address];
  rawData1 = [
    "0x" +
    "0" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    IArbStableSwap2.address.replace("0x", ""), // Pool
  ];
  info =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256", "uint256"],
    [
      WETHContract.address,
      wstETHContract.address,
      1,
      0
    ]
  )
  moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["uint8", "bytes"],
    [
      0, // stable swap
      info
    ]);
  extraData1 = [moreinfo];
  router1 = [mixAdapter1, assetTo1, rawData1, extraData1, WETHContract.address];
  layer1 = [router1];
  orderId = 1;
  baseRequest = [
    WETHContract.address,
    wstETHContract.address,
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
    await wstETHContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await wstETHContract.balanceOf(userAddress),
      await wstETHContract.decimals()
    )
  );
  console.log(
    "2nd swap:",
    await WETHContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await WETHContract.balanceOf(userAddress),
      await WETHContract.decimals()
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

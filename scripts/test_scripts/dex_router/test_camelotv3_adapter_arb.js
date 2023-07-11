const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, FOREVER } = require("./utils");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arb");

const pool_address = "0xb7Dd20F3FBF4dB42Fd85C839ac0241D09F72955f"; // WETH-USDC.e

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 105638200);
  let { dexRouter, tokenApprove } = await initDexRouter(
    tokenConfig.tokens.WETH.baseTokenAddress
  );

  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let camelotV3Adapter = await ethers.getContractFactory("CamelotV3Adapter");
  let CamelotV3Adapter = await camelotV3Adapter.connect(depolyer).deploy(tokenConfig.tokens.WETH.baseTokenAddress);
  await CamelotV3Adapter.connect(depolyer).deployed();

  let ICamelotV3Pool = await ethers.getContractAt("ICamelotV3Pool", pool_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  let [token0, token1] = [
    await ICamelotV3Pool.token0(),
    await ICamelotV3Pool.token1(),
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



  /*
  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *   Start First Swap    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  */

  // 1. swap USDC -> WETH
  // parameters about 2000 USDC -> WETH
  let fromTokenAmount = ethers.utils.parseUnits(
    "2000",
    await USDCContract.decimals()
  );
  const minReturnAmount = 0;
  const deadLine = FOREVER;
  let mixAdapter1 = [CamelotV3Adapter.address];
  let assetTo1 = [CamelotV3Adapter.address];
  let weight1 = Number(10000).toString(16).replace("0x", "");
  let rawData1 = [
    "0x" +
    "8" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    ICamelotV3Pool.address.replace("0x", ""), // Pool
  ];
  let moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["uint160", "bytes"],
    [
      0,
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [USDCContract.address, WETHContract.address]
      ),
    ]
  );
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
  // 2. swap WETH -> USDC
  let wethBalance = await WETHContract.balanceOf(userAddress);
  fromTokenAmount = wethBalance.div(2);
  rawData1 = [
    "0x" +
    "0" + // 0: sellBase / 8: sellQuote
    "0000000000000000000" +
    weight1 +
    ICamelotV3Pool.address.replace("0x", ""), // Pool
  ];
  moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["uint160", "bytes"],
    [
      0,
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [WETHContract.address, USDCContract.address]
      ),
    ]
  );
  extraData1 = [moreinfo];
  router1 = [
    mixAdapter1,
    assetTo1,
    rawData1,
    extraData1,
    WETHContract.address,
  ];
  layer1 = [router1];
  orderId = 1;
  baseRequest = [
    WETHContract.address,
    USDCContract.address,
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

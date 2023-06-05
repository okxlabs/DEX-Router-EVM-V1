const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { initDexRouter, FOREVER } = require("./utils");

const pool_address = "0x3333333ACdEdBbC9Ad7bda0876e60714195681c5";

async function execute() {
  // Eth Network
  const tokenConfig = getConfig("eth");
  await setForkBlockNumber(17340000);
  let { dexRouter, tokenApprove } = await initDexRouter(
    tokenConfig.tokens.WETH.baseTokenAddress
  );
  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let xSigmaAdapter = await ethers.getContractFactory("XSigmaAdapter");
  let XSigmaAdapter = await xSigmaAdapter.connect(depolyer).deploy();
  await XSigmaAdapter.connect(depolyer).deployed();

  let userAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  // 0: DAI
  let DaiContract = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.DAI.baseTokenAddress
  );
  // 1: USDC
  let USDCContract = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDC.baseTokenAddress
  );
  // 2: USDT
  let USDTContract = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDT.baseTokenAddress
  );

  // check user token
  console.log(
    await DaiContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await DaiContract.balanceOf(userAddress),
      await DaiContract.decimals()
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
  console.log(
    await USDTContract.symbol(),
    "before balance:",
    ethers.utils.formatUnits(
      await USDTContract.balanceOf(userAddress),
      await USDTContract.decimals()
    )
  );

  // parameters about USDT -> DAI
  const fromTokenAmount = ethers.utils.parseUnits(
    "100",
    tokenConfig.tokens.USDT.decimals
  );
  const minReturnAmount = 0;
  const deadLine = FOREVER;
  const mixAdapter1 = [XSigmaAdapter.address];
  const assetTo1 = [XSigmaAdapter.address];
  const weight1 = Number(10000).toString(16).replace("0x", "");
  const rawData1 = [
    "0x" +
      "0" + // 0/8
      "0000000000000000000" +
      weight1 +
      pool_address.replace("0x", ""), // Pool
  ];
  const moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128"],
    [USDTContract.address, DaiContract.address, 2, 0]
  );
  const extraData1 = [moreinfo];
  const router1 = [
    mixAdapter1,
    assetTo1,
    rawData1,
    extraData1,
    USDTContract.address,
  ];
  const layer1 = [router1];
  const orderId = 0;
  const baseRequest = [
    USDTContract.address,
    DaiContract.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ];

  //tx
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

  // result
  console.log(
    await DaiContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await DaiContract.balanceOf(userAddress),
      await DaiContract.decimals()
    )
  );
  console.log(
    await USDCContract.symbol(),
    "after balance:",
    ethers.utils.formatUnits(
      await USDCContract.balanceOf(userAddress),
      await USDCContract.decimals()
    )
  );
  console.log(
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

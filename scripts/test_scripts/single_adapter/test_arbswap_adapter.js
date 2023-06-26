const { ethers } = require("hardhat");
require("../../tools");

const pair1_address = "0x6E8AEE8Ed658fDCBbb7447743fdD98152B3453A0"; // WETH-USDC

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 101451200);

  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let arbswapAdapter = await ethers.getContractFactory("ArbSwapAdapter");
  let ArbSwapAdapter = await arbswapAdapter.connect(depolyer).deploy();
  await ArbSwapAdapter.connect(depolyer).deployed();

  let IArbSwapPair = await ethers.getContractAt("IArbSwapPair", pair1_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  let [token0, token1] = [
    await IArbSwapPair.token0(),
    await IArbSwapPair.token1(),
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

  // 1. swap USDC -> WETH
  await USDCContract.connect(signer).transfer(
    pair1_address,
    ethers.utils.parseUnits("2000", await USDCContract.decimals())
  );
  let moreinfo = ethers.utils.defaultAbiCoder.encode([], []);
  await ArbSwapAdapter.sellQuote(userAddress, pair1_address, moreinfo);

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

  // 2. swap WETH -> USDC
  let wethBalance = await WETHContract.balanceOf(userAddress);
  await WETHContract.connect(signer).transfer(
    pair1_address,
    wethBalance.div(2)
  );
  await ArbSwapAdapter.sellBase(userAddress, pair1_address, moreinfo);

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

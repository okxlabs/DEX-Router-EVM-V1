const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arb");

const pool_address = "0xb7Dd20F3FBF4dB42Fd85C839ac0241D09F72955f"; // WETH-USDC.e

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 105638100);

  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let camelotV3Adapter = await ethers.getContractFactory("CamelotV3Adapter");
  let CamelotV3Adapter = await camelotV3Adapter
    .connect(depolyer)
    .deploy(tokenConfig.tokens.WETH.baseTokenAddress);
  await CamelotV3Adapter.connect(depolyer).deployed();

  let ICamelotV3Pool = await ethers.getContractAt(
    "ICamelotV3Pool",
    pool_address
  );

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

  // 1. swap USDC -> WETH
  await USDCContract.connect(signer).transfer(
    CamelotV3Adapter.address,
    ethers.utils.parseUnits("2000", await USDCContract.decimals())
  );
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
  await CamelotV3Adapter.sellQuote(userAddress, pool_address, moreinfo);

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
    CamelotV3Adapter.address,
    wethBalance.div(2)
  );
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
  await CamelotV3Adapter.sellBase(userAddress, pool_address, moreinfo);

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

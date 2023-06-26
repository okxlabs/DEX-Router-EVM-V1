const { ethers } = require("hardhat");
require("../../tools");

const pair1_address = "0xE97Af01c48C0A332C06A92dF36b77B2A680AB54B"; // USDT-USDC stable
const pair2_address = "0xE7dE07F541EBeCcA39aB65CA2203bc54B7107353"; // wstETH-WETH stable

async function execute() {
  // Network arbitrum
  await setForkNetWorkAndBlockNumber("arbitrum", 103064000);

  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let arbSwapV2Adapter = await ethers.getContractFactory("ArbSwapV2Adapter");
  let ArbSwapV2Adapter = await arbSwapV2Adapter.connect(depolyer).deploy();
  await ArbSwapV2Adapter.connect(depolyer).deployed();

  let IArbStableSwap = await ethers.getContractAt("IArbStableSwap", pair1_address);

  // super rich address
  let userAddress = "0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  let [token0, token1] = [
    await IArbStableSwap.coins(0),
    await IArbStableSwap.coins(1),
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
    ArbSwapV2Adapter.address,
    ethers.utils.parseUnits("2000", await USDCContract.decimals())
  );
  let info =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256", "uint256"],
    [
      USDCContract.address,
      USDTContract.address,
      1,
      0
    ]
  )
  let moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["uint8", "bytes"],
    [
      0,
      info
    ]);
  await ArbSwapV2Adapter.sellQuote(userAddress, pair1_address, moreinfo);

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
    ArbSwapV2Adapter.address,
    ethers.utils.parseUnits("2000", await USDTContract.decimals())
  );
  info =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256", "uint256"],
    [
      USDTContract.address,
      USDCContract.address,
      0,
      1
    ]
  )
  moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["uint8", "bytes"],
    [
      0,
      info
    ]);
  await ArbSwapV2Adapter.sellBase(userAddress, pair1_address, moreinfo);

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

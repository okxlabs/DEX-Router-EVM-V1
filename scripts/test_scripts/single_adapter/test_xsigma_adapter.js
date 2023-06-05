const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

const pool_address = "0x3333333ACdEdBbC9Ad7bda0876e60714195681c5";

async function execute() {
  // Network Main
  await setForkBlockNumber(17340000);
  // deploy adapter
  [user1, depolyer] = await ethers.getSigners();
  let xSigmaAdapter = await ethers.getContractFactory("XSigmaAdapter");
  let XSigmaAdapter = await xSigmaAdapter.connect(depolyer).deploy();
  await XSigmaAdapter.connect(depolyer).deployed();

  let userAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296";
  startMockAccount([userAddress]);
  let signer = await ethers.getSigner(userAddress);

  const tokenConfig = getConfig("eth");
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

  // swap USDT -> USDC
  await USDTContract.connect(signer).transfer(
    XSigmaAdapter.address,
    ethers.utils.parseUnits("200", await USDTContract.decimals())
  );
  let moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128"],
    [USDTContract.address, USDCContract.address, 2, 1]
  );
  await XSigmaAdapter.sellQuote(userAddress, pool_address, moreinfo);

  // swap USDC -> DAI
  await USDCContract.connect(signer).transfer(
    XSigmaAdapter.address,
    ethers.utils.parseUnits("100", await USDCContract.decimals())
  );
  moreinfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128"],
    [USDCContract.address, DaiContract.address, 1, 0]
  );
  await XSigmaAdapter.sellQuote(userAddress, pool_address, moreinfo);

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

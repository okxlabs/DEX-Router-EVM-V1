const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function deployContract() {
  config = getConfig("eth");

  LidoAdapter = await ethers.getContractFactory("LidoAdapter");
  lidoAdapter = await LidoAdapter.deploy(config.tokens.WETH.baseTokenAddress);
  await lidoAdapter.deployed();
  return lidoAdapter;
}

async function executeWstETH2stETH(lidoAdapter) {
  config = getConfig("eth");

  userAddress = "0x741AA7CFB2c7bF2A1E7D4dA2e3Df6a56cA4131F3";
  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);
  await setBalance(userAddress, "0x53444835ec580000");

  const WETH = await ethers.getContractAt(
    "MockERC20",
    config.tokens.WETH.baseTokenAddress
  );

  const stETH = await ethers.getContractAt(
    "MockERC20",
    "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
  );

  QuoteBalance = await stETH.balanceOf(userAddress);
  console.log("User stETH beforeBalance: ", QuoteBalance.toString());
  BaseBalance = await WETH.balanceOf(userAddress);
  console.log("User weth beforeBalance: ", (BaseBalance / 1e18).toString());

  const fromAmount = ethers.utils.parseEther("10");
  await WETH.connect(signer).transfer(lidoAdapter.address, fromAmount);

  const poolAddress = "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84";

  // swap
  await lidoAdapter.sellBase(
    signer.address,
    ethers.utils.getAddress(poolAddress),
    ethers.utils.defaultAbiCoder.encode(
      ["uint256"],
      ["0x00000000000000000000000000000000000000000000000000000000000000"]
    )
  );

  BaseBalance = await WETH.balanceOf(userAddress);
  console.log("User weth afterBalance: ", (BaseBalance / 1e18).toString());
  QuoteBalance = await stETH.balanceOf(userAddress);
  console.log("User stETH afterBalance: ", QuoteBalance.toString());

  console.log("=== execute WstETH swap to stETH end ===");
}

async function executestETH2WETH(lidoAdapter) {
  config = getConfig("eth");

  userAddress = "0xB6DC2a1A65DF16D0C34f0DA442Aa2a9a5315030a";
  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);
  await setBalance(userAddress, "0x53444835ec580000");

  const stETH = await ethers.getContractAt(
    "MockERC20",
    "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
  );

  const wstETH = await ethers.getContractAt(
    "MockERC20",
    "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
  )

  QuoteBalance = await stETH.balanceOf(userAddress);
  console.log("User stETH afterBalance: ", QuoteBalance.toString());
  BaseBalance = await wstETH.balanceOf(userAddress);
  console.log("User wstETH afterBalance: ", BaseBalance.toString());

  const fromAmount = ethers.utils.parseEther("10");
  await stETH.connect(signer).transfer(lidoAdapter.address, fromAmount);

  // stETH
  const poolAddress = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0";

  // swap
  await lidoAdapter.sellQuote(
    signer.address,
    ethers.utils.getAddress(poolAddress),
    ethers.utils.defaultAbiCoder.encode(
      ["uint256"],
      ["0x11000000000000000000000000000000000000000000000000000000000000"]
    )
  );

  QuoteBalance = await stETH.balanceOf(userAddress);
  console.log("User stETH afterBalance: ", QuoteBalance.toString());
  BaseBalance = await wstETH.balanceOf(userAddress);
  console.log("User wstETH afterBalance: ", BaseBalance.toString());

  console.log("=== execute stETH swap to wstETH end ===");
}

async function main() {
  setForkNetWorkAndBlockNumber("eth", 16995518);
  LidoAdapter = await deployContract();
  await executeWstETH2stETH(LidoAdapter);

  setForkNetWorkAndBlockNumber("eth", 17072855);
  LidoAdapter = await deployContract();
  await executestETH2WETH(LidoAdapter);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

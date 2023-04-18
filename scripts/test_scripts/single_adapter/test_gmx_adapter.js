const { ethers } = require("hardhat");
const { setBalance } = require("../../../tools/chain");
require("../../../tools");

async function deployContract() {
  GmxAdapter = await ethers.getContractFactory("GmxAdapter");
  GmxAdapter = await GmxAdapter.deploy();
  await GmxAdapter.deployed();
  return GmxAdapter;
}

// Arbitrum：
// Vault: 0x489ee077994B6658eAfA855C308275EAd8097C4A
// WBTC:  0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f
// WETH:  0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
// USDC:  0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
// LINK:  0xf97f4df75117a78c1A5a0DBb814Af92458539FB4
// UNI:   0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0
// USDT:  0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
// MIM:   0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A
// FRAX:  0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F
// DAI:   0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
// userAddress: 0x44311c91008DDE73dE521cd25136fD37d616802c

// Avalanche：
// Vault:  0x9ab2De34A33fB459b538c43f251eB825645e8595
// WAVAX:  0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
// WBTC.e: 0x50b7545627a5162F82A992c33b87aDc75187B218
// WETH.e  0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB
// MIM:    0x130966628846BFd36ff31a822705796e8cb8C18D
// USDC.e: 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664
// USDC: 	 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
// BTC.b:  0x152b9d0FdC40C096757F570A51E494bd4b943E50
// userAddress 0x7858A4C42C619a68df6E95DF7235a9Ec6F0308b9

async function execute(GmxAdapter) {
  userAddress = "0x44311c91008DDE73dE521cd25136fD37d616802c";
  poolAddress = "0x489ee077994B6658eAfA855C308275EAd8097C4A";
  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // Quote Token
  Quote = await ethers.getContractAt(
    "MockERC20",
    "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
  );

  // Base Token
  Base = await ethers.getContractAt(
    "MockERC20",
    "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f"
  );

  // check user token
  QuoteBalance = await Quote.balanceOf(userAddress);
  console.log("User Quote beforeBalance: ", QuoteBalance.toString());
  BaseBalance = await Base.balanceOf(userAddress);
  console.log("User Base beforeBalance: ", BaseBalance.toString());

  console.log("\n================== SellQuote ==================");
  // transfer quote token to vault
  //fromAmount = ethers.utils.parseEther("0.001");
  await Quote.connect(signer).transfer(poolAddress, QuoteBalance);

  // swap
  rxResult = await GmxAdapter.sellQuote(
    signer.address,
    poolAddress,
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address"],
      [Quote.address, Base.address]
    )
  );

  QuoteBalance = await Quote.balanceOf(userAddress);
  console.log("User Quote afterBalance: ", QuoteBalance.toString());
  BaseBalance = await Base.balanceOf(userAddress);
  console.log("User Base afterBalance: ", BaseBalance.toString());

  console.log("\n================== SellBase ==================");
  // transfer base token to vault
  await Base.connect(signer).transfer(
    poolAddress,
    await Base.balanceOf(signer.address)
  );

  // swap
  rxResult = await GmxAdapter.sellBase(
    signer.address,
    poolAddress,
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address"],
      [Base.address, Quote.address]
    )
  );

  QuoteBalance = await Quote.balanceOf(signer.address);
  console.log("User Quote afterBalance: ", QuoteBalance.toString());
  BaseBalance = await Base.balanceOf(signer.address);
  console.log("User Base afterBalance: ", BaseBalance.toString());
}

async function main() {
  setForkNetWorkAndBlockNumber("arbitrum", 22118637);
  GmxAdapter = await deployContract();
  console.log("===== GmxAdapter =====");
  await execute(GmxAdapter);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

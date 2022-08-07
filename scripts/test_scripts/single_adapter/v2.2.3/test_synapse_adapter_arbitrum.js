const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("arbitrum")


async function deployContract() {
    SynapseAdapter = await ethers.getContractFactory("SynapseAdapter");
    SynapseAdapter = await SynapseAdapter.deploy();
    await SynapseAdapter.deployed();
    return SynapseAdapter
}


// WETH:nETH Pool https://synapseprotocol.com/pools/arbitrumethpool
// nETH address: 0x3ea9B0ab55F34Fb188824Ee288CeaEfC63cf908e
// WETH address: 0x82af49447d8a07e3bd95bd0d56f35241523fbab1
// Pool address: 0x1c3fe783a7c06bfAbd124F2708F5Cc51fA42E102

async function executeTwoCrypto(SynapseAdapter) {
  
  UserAddress = "0x905dfcd5649217c42684f23958568e533c711aa3"
  ETH_nETHPool = "0xa067668661C84476aFcDc6fA5D758C4c01C34352"  

  startMockAccount([UserAddress])
  signer = await ethers.getSigner(UserAddress)
  await setBalance(UserAddress, "0x53444835ec580000");

  // tokenIndex: 1
  // Tips: ETH's tokenIndex: 1
  WETH = await ethers.getContractAt(
      "MockERC20",
      "0x82af49447d8a07e3bd95bd0d56f35241523fbab1"
  )

  // tokenIndex: 0
  nETH = await ethers.getContractAt(
      "MockERC20",
      "0x3ea9B0ab55F34Fb188824Ee288CeaEfC63cf908e"
  )

  // transfer token
  await WETH.connect(signer).transfer(SynapseAdapter.address, ethers.utils.parseEther("10"));

  WETHBeforeBalance = await WETH.balanceOf(SynapseAdapter.address);
  nETHAfterBalance = await nETH.balanceOf(SynapseAdapter.address);
  console.log("WETH before balance: ", WETHBeforeBalance.toString());
  console.log("nETH before balance: ", nETHAfterBalance.toString());

  const DDL = 2541837122

  moreinfo =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
        WETH.address,
        nETH.address,
        DDL
    ]
  )

  rxResult = await SynapseAdapter.sellQuote(
    SynapseAdapter.address,
    ETH_nETHPool,
    moreinfo
  );

  WETHafterBalance = await WETH.balanceOf(SynapseAdapter.address)
  afterBalance = await nETH.balanceOf(SynapseAdapter.address)
  console.log("WETH after balance: ", WETHafterBalance.toString());
  console.log("SETH after balance: ", afterBalance.toString());
}

// USDT:USDC:nUSD https://synapseprotocol.com/pools/arbitrum3pool
// pool address: 0x9Dd329F5411466d9e0C488fF72519CA9fEf0cb40
// nUSD address: 0x2913E812Cf0dcCA30FB28E6Cac3d2DCFF4497688
// nUSD holder:  0x9dd329f5411466d9e0c488ff72519ca9fef0cb40
// USDT address: 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9


async function executeTricrypto(SynapseAdapter) {  

    UserAddress = "0x9dd329f5411466d9e0c488ff72519ca9fef0cb40"
    triCryptoAddress = "0x9Dd329F5411466d9e0C488fF72519CA9fEf0cb40"

    await setBalance(UserAddress, "0x53444835ec580000");
    startMockAccount([UserAddress])

    signer = await ethers.getSigner(UserAddress)

    // USDT
    // tokenIndex: 2
    USDT = await ethers.getContractAt(
        "MockERC20",
        "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9"
    )
    // tokenIndex: 0
    nUSD = await ethers.getContractAt(
        "MockERC20",
        "0x2913E812Cf0dcCA30FB28E6Cac3d2DCFF4497688"
    )

    // check user token
    beforeBalance = await USDT.balanceOf(UserAddress);
    console.log("user balance: ", beforeBalance.toString());
    
    // transfer token
    await USDT.connect(signer).transfer(SynapseAdapter.address, ethers.utils.parseUnits('30', tokenConfig.tokens.USDT.decimals));
    beforeBalance = await USDT.balanceOf(SynapseAdapter.address);

    console.log("USDT beforeBalance: ", beforeBalance.toString());

    // swap
    beforeBalance = await nUSD.balanceOf(SynapseAdapter.address);
    console.log("nUSD beforeBalance: ", beforeBalance.toString());

    // 2050-07-19 17:52:02
    const DDL = 2541837122

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256"],
      [
          "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
          "0x2913E812Cf0dcCA30FB28E6Cac3d2DCFF4497688",
          DDL
      ]
    )
    rxResult = await SynapseAdapter.sellQuote(
      SynapseAdapter.address,
      triCryptoAddress,
      moreinfo
    );

    afterBalance = await nUSD.balanceOf(SynapseAdapter.address);
    usdtBalance = await USDT.balanceOf(SynapseAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("nUSD afterBalance: ", afterBalance.toString());
}

async function main() {  
  SynapseAdapter = await deployContract()
  console.log("==== checking Tricrypto ====== ")
  await executeTricrypto(SynapseAdapter);

  console.log("==== checking TwoCrypto ====== ")
  await executeTwoCrypto(SynapseAdapter);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

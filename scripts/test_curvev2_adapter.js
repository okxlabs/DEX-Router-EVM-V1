const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("./tools");
const { getConfig } = require("./config");
const tokenConfig = getConfig("eth")
// lido: 
// ETH/stETH
// https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#code
// exchange

// Curve.fi
// ETH/sETH
// https://etherscan.io/address/0xc5424b857f758e906013f3555dad202e4bdb4567#code
// #	Name	Type	Data
// 0	i	int128	1
// 1	j	int128	0
// 2	dx	uint256	9999462000000000000
// 3	min_dy	uint256	9892080930600000000

// Curve.fi
// tricrypto: USDT/WBTC/WETH or similar
// https://etherscan.io/address/0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5#code

async function deployContract() {
    CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
    CurveV2Adapter = await CurveV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await CurveV2Adapter.deployed();
    
    return CurveV2Adapter
}


async function executeTwoCrypto(CurveV2Adapter) {
  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e"
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress)

  await setBalance(accountAddress, "0x53444835ec580000");
  await setBalance(CurveV2Adapter.address, "0x53444835ec580000");

  ETH_SETHPool = "0xc5424b857f758e906013f3555dad202e4bdb4567"  

  WETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  SETHContract = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.SETH.baseTokenAddress
  )
  await WETH.connect(account).transfer(CurveV2Adapter.address, ethers.utils.parseEther('3.5'));

  WETHBeforeBalance = await WETH.balanceOf(CurveV2Adapter.address);
  SETHAfterBalance = await SETHContract.balanceOf(CurveV2Adapter.address);
  console.log("WETH before balance: ", WETHBeforeBalance.toString());
  console.log("SETH before balance: ", SETHAfterBalance.toString());

  beforeBalance = await SETHContract.balanceOf(CurveV2Adapter.address);
  
  

  moreinfo =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128"],
    [
        tokenConfig.tokens.ETH.baseTokenAddress,
        tokenConfig.tokens.SETH.baseTokenAddress,
        0,
        1
    ]
  )
  rxResult = await CurveV2Adapter.sellQuote(
    CurveV2Adapter.address,
    ETH_SETHPool,
    moreinfo
  );














  wETHafterBalance = await WETH.balanceOf(CurveV2Adapter.address)
  afterBalance = await SETHContract.balanceOf(CurveV2Adapter.address)
  console.log("WETH after balance: ", wETHafterBalance.toString());
  console.log("SETH after balance: ", afterBalance.toString());


}

async function executeTricrypto(CurveV2Adapter) {  

    await setBalance(CurveV2Adapter.address, "0x53444835ec580000");

    UserAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    triCryptoAddress = "0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5"

    startMockAccount([UserAddress])

    signer = await ethers.getSigner(UserAddress)

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )
    WBTCContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WBTC.baseTokenAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(UserAddress);
    console.log("user balance: ", beforeBalance.toString());
    
    // transfer token
    await USDTContract.connect(signer).transfer(CurveV2Adapter.address, ethers.utils.parseUnits('1000', tokenConfig.tokens.USDT.decimals));
    beforeBalance = await USDTContract.balanceOf(CurveV2Adapter.address);

    console.log("USDT beforeBalance: ", beforeBalance.toString());

    // swap
    beforeBalance = await WBTCContract.balanceOf(CurveV2Adapter.address);
    console.log("WBTC beforeBalance: ", beforeBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128"],
      [
          tokenConfig.tokens.USDT.baseTokenAddress,
          tokenConfig.tokens.WBTC.baseTokenAddress,
          0,
          1
      ]
    )
    rxResult = await CurveV2Adapter.sellQuote(
      CurveV2Adapter.address,
      triCryptoAddress,
      moreinfo
    );
    // console.log(rxResult)

    afterBalance = await WBTCContract.balanceOf(CurveV2Adapter.address);
    usdtBalance = await USDTContract.balanceOf(CurveV2Adapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("WBTC afterBalance: ", afterBalance.toString());
}

async function main() {  
  CurveV2Adapter = await deployContract()
  console.log("==== checking Tricrypto ====== ")
  await executeTricrypto(CurveV2Adapter);
  console.log("==== checking TwoCrypto ====== ")
  await executeTwoCrypto(CurveV2Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

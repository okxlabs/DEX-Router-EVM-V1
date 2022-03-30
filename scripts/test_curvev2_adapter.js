const { ethers } = require("hardhat");
require("./tools");

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
    CurveV2Adapter = await CurveV2Adapter.deploy();
    await CurveV2Adapter.deployed();
    return CurveV2Adapter
}

//   const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }


async function executeTwoCrypto(CurveV2Adapter) {
  ETHAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
  ETH_SETHPool = "0xc5424b857f758e906013f3555dad202e4bdb4567"
  sETHAddress = "0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb"
  // set account balance 0.6 eth
  await setBalance(CurveV2Adapter.address, "0x53444835ec580000");

  SETHContract = await ethers.getContractAt(
    "MockERC20",
    sETHAddress
  )

  beforeBalance = await SETHContract.balanceOf(CurveV2Adapter.address)
  moreinfo =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128", "bool"],
    [
        ETHAddress,
        sETHAddress,
        0,
        1,
        true
    ]
  )
  rxResult = await CurveV2Adapter.sellQuote2(
    CurveV2Adapter.address,
    ETH_SETHPool,
    moreinfo
  );
  afterBalance = await SETHContract.balanceOf(CurveV2Adapter.address)
  console.log("SETH before balance: ", usdtBalance.toString());
  console.log("SETH after balance: ", afterBalance.toString());


}

async function executeTricrypto(CurveV2Adapter) {  
    UserAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    UsdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    WBTCAddress = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
    triCryptoAddress = "0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5"

    startMockAccount([UserAddress])

    signer = await ethers.getSigner(UserAddress)

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      UsdtAddress
    )
    WBTCContract = await ethers.getContractAt(
      "MockERC20",
      WBTCAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(UserAddress);
    console.log("user balance: ", beforeBalance.toString());
    
    // transfer token
    await USDTContract.connect(signer).transfer(CurveV2Adapter.address, ethers.utils.parseUnits('1000', 6));
    beforeBalance = await USDTContract.balanceOf(CurveV2Adapter.address);

    console.log("USDT beforeBalance: ", beforeBalance.toString());

    // swap
    beforeBalance = await WBTCContract.balanceOf(CurveV2Adapter.address);
    console.log("WBTC beforeBalance: ", beforeBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256", "uint256", "bool"],
      [
          UsdtAddress,
          WBTCAddress,
          0,
          1,
          false
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

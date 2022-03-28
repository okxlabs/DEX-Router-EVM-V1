const { ethers } = require("hardhat");
require("./tools");


// # Pool for USDT/WBTC/WETH or similar
// triCrypto address: 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5

// block: 14063215 
// 0	i	uint256	0
// 1	j	uint256	1
// 2	dx	uint256	4769164346
// 3	min_dy	uint256	13380240
// 4	use_eth	bool	true
// 4,769.164346 USDT
// 0.13515394 WBTC

async function execute() {  
    UserAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    UsdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    WBTCAddress = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
    triCryptoAddress = "0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5"

    startMockAccount([UserAddress])

    signer = await ethers.getSigner(UserAddress)

    // 获得
    CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
    CurveV2Adapter = await CurveV2Adapter.deploy();
    await CurveV2Adapter.deployed();

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
      ["address", "address", "int128", "int128", "bool"],
      [
          UsdtAddress,
          WBTCAddress,
          0,
          1,
          true
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
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
const tokenConfig = getConfig("arbitrum")


async function deployContract() {
    CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
    CurveV2Adapter = await CurveV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await CurveV2Adapter.deployed();
    return CurveV2Adapter
}

// https://arbiscan.io/address/0x960ea3e3C7FB317332d990873d354E18d7645590#code
// USDT: WETH : BTC
// 0: USDT
// 1: WBTC
// 2: WETH

async function executeTricrypto(CurveV2Adapter) {  

    await setBalance(CurveV2Adapter.address, "0x53444835ec580000");

    UserAddress = "0xa97Bd3094fB9Bf8a666228bCEFfC0648358eE48F"
    triCryptoAddress = "0x960ea3e3C7FB317332d990873d354E18d7645590"

    startMockAccount([UserAddress])

    signer = await ethers.getSigner(UserAddress)

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )
    WETH = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(UserAddress);
    console.log("user balance: ", beforeBalance.toString());
    
    // transfer token
    await USDTContract.connect(signer).transfer(CurveV2Adapter.address, ethers.utils.parseUnits('1000', tokenConfig.tokens.USDT.decimals));
    beforeBalance = await USDTContract.balanceOf(CurveV2Adapter.address);

    console.log("USDT beforeBalance: ", beforeBalance.toString());

    // swap
    beforeBalance = await WETH.balanceOf(CurveV2Adapter.address);
    console.log("WETH beforeBalance: ", beforeBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128"],
      [
          tokenConfig.tokens.USDT.baseTokenAddress,
          tokenConfig.tokens.WETH.baseTokenAddress,
          0,
          2
      ]
    )
    rxResult = await CurveV2Adapter.sellQuote(
      CurveV2Adapter.address,
      triCryptoAddress,
      moreinfo
    );
    // console.log(rxResult)

    afterBalance = await WETH.balanceOf(CurveV2Adapter.address);
    usdtBalance = await USDTContract.balanceOf(CurveV2Adapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("WETH afterBalance: ", afterBalance.toString());
}

async function main() {  
  CurveV2Adapter = await deployContract()
  console.log("==== checking Tricrypto ====== ")
  await executeTricrypto(CurveV2Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

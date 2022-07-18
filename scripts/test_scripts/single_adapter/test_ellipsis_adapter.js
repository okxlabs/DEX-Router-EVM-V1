const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { USDT } = require("../../config/okc/tokens");
const tokenConfig = getConfig("eth")


async function deployContract() {
    EllipsisAdapter = await ethers.getContractFactory("EllipsisAdapter");
    EllipsisAdapter = await EllipsisAdapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await EllipsisAdapter.deployed();
    
    return EllipsisAdapter
}

// stable coin: USDT => DAI
async function Erc20ToErc20(EllipsisAdapter) {
    
    UserAddress = "0xf977814e90da44bfa03b6295a0616a897441acec"
    poolAddress = "0x160caed03795365f3a589f10c379ffa7d75d4e76"

    startMockAccount([UserAddress])
    signer = await ethers.getSigner(UserAddress)

    // prepare USDT Token
    // holder: 0xf977814e90da44bfa03b6295a0616a897441acec
    USDT = await ethers.getContractAt(
        "MockERC20",
        "0x55d398326f99059fF775485246999027B3197955"
      )
    // perapre DAI Token
    DAI = await ethers.getContractAt(
        "MockERC20",
        "0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3"
    )

    await USDT.connect(signer).transfer(EllipsisAdapter.address, ethers.utils.parseUnits('1000', tokenConfig.tokens.USDT.decimals));
    USDTbeforeBalance = await USDT.balanceOf(EllipsisAdapter.address);
    DAIbeforeBalance = await DAI.balanceOf(EllipsisAdapter.address);

    // swap
    // UDST: 2
    // DAI: 1

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            USDT.address,
            DAI.address,
            2,
            1
        ]
      )
      rxResult = await CurveV2Adapter.sellQuote(
        EllipsisAdapter.address,
        poolAddress,
        moreinfo
      );

    // check balance
    USDTAftereBalance = await USDT.balanceOf(EllipsisAdapter.address);
    DAIAfterBalance = await DAI.balanceOf(EllipsisAdapter.address);
    console.log("usdt balance: ", USDTAftereBalance)

}




async function main() {  
    EllipsisAdapter = await deployContract()
    await Erc20ToErc20(EllipsisAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

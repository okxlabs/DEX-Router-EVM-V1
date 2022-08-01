const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const tokenConfig = getConfig("bsc")


async function deployContract() {
    EllipsisAdapter = await ethers.getContractFactory("EllipsisAdapter");
    console.log("WBNB: ")
    console.log(tokenConfig.tokens.WBNB.baseTokenAddress)
    EllipsisAdapter = await EllipsisAdapter.deploy(tokenConfig.tokens.WBNB.baseTokenAddress);
    await EllipsisAdapter.deployed();
    
    return EllipsisAdapter
}

// stable coin: USDT => USDC
async function Erc20ToErc20(EllipsisAdapter) {

    // fork network
    // await setForkNetWorkAndBlockNumber("bsc")
    
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
    USDC = await ethers.getContractAt(
        "MockERC20",
        "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"
    )

    await USDT.connect(signer).transfer(EllipsisAdapter.address, ethers.utils.parseEther("1000"));
    USDTbeforeBalance = await USDT.balanceOf(EllipsisAdapter.address);
    USDCbeforeBalance = await USDC.balanceOf(EllipsisAdapter.address);

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "int128", "int128"],
        [
            USDT.address,
            USDC.address,
            2,
            1
        ]
      )
    rxResult = await EllipsisAdapter.sellQuote(
      EllipsisAdapter.address,
      poolAddress,
      moreinfo
    );

    // check balance
    USDTAftereBalance = await USDT.balanceOf(EllipsisAdapter.address);
    USDCAfterBalance = await USDC.balanceOf(EllipsisAdapter.address);
    console.log("usdt before balance: ", USDTbeforeBalance.toString(), "usdt after balance: ", USDTAftereBalance.toString())
    console.log("usdc before balance: ", USDCbeforeBalance.toString(), "usdt after balance: ", USDCAfterBalance.toString())
}

// stable coin: BNB => ZBNB
async function NativeToErc20(EllipsisAdapter) {

  UserAddress = "0xa3f5396b80effa6a226bcbb51a1f1ae61e2421e3"
  poolAddress = "0x51d5B7A71F807C950A45dD8b1400E83826Fc49F3"

  startMockAccount([UserAddress])
  signer = await ethers.getSigner(UserAddress)

  WBNB = await ethers.getContractAt(
     "MockERC20",
     tokenConfig.tokens.WBNB.baseTokenAddress
  )
  ZBNB = await ethers.getContractAt(
     "MockERC20",
      "0x6DEdCEeE04795061478031b1DfB3c1ddCA80B204"
  )

  // prepare BNB
  await WBNB.connect(signer).transfer(EllipsisAdapter.address, ethers.utils.parseEther("20"));

  // check balance
  ZBNBBeforeBalance = await ZBNB.balanceOf(EllipsisAdapter.address);
  console.log( "ZBNBBeforeBalance: ", ZBNBBeforeBalance.toString())


  moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128"],
      [
          tokenConfig.tokens.BNB.baseTokenAddress,
          ZBNB.address,
          0,
          1
      ]
    )
  rxResult = await EllipsisAdapter.sellQuote(
    EllipsisAdapter.address,
    poolAddress,
    moreinfo
  );

  // check balance
  ZBNBAftereBalance = await ZBNB.balanceOf(EllipsisAdapter.address);

  console.log( "ZBNBAftereBalance: ", ZBNBAftereBalance.toString())
}

// stable coin: ZBNB => BNB
async function ERC20ToNative(EllipsisAdapter) {
  UserAddress = "0xa3f5396b80effa6a226bcbb51a1f1ae61e2421e3"
  poolAddress = "0x51d5B7A71F807C950A45dD8b1400E83826Fc49F3"

  startMockAccount([UserAddress])
  signer = await ethers.getSigner(UserAddress)

  // perapre DAI Token
  WBNB = await ethers.getContractAt(
     "MockERC20",
     tokenConfig.tokens.WBNB.baseTokenAddress
  )
  ZBNB = await ethers.getContractAt(
     "MockERC20",
      "0x6DEdCEeE04795061478031b1DfB3c1ddCA80B204"
  )

  // check balance
  ZBNBAfterBalance = await ZBNB.balanceOf(EllipsisAdapter.address)
  WBNBAftereBalance = await WBNB.balanceOf(signer.address);
  console.log( "WBNBAftereBalance: ", WBNBAftereBalance.toString(), ", ZBNBAfterBalance: ", ZBNBAfterBalance.toString())

  moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128"],
      [
          ZBNB.address,
          tokenConfig.tokens.BNB.baseTokenAddress,
          1,
          0
      ]
    )
  rxResult = await EllipsisAdapter.sellQuote(
    signer.address,
    poolAddress,
    moreinfo
  );

  // check balance
  ZBNBAfterBalance = await ZBNB.balanceOf(EllipsisAdapter.address)
  WBNBAftereBalance = await WBNB.balanceOf(signer.address);

  console.log( "WBNBAftereBalance: ", WBNBAftereBalance.toString(), ", ZBNBAfterBalance: ", ZBNBAfterBalance.toString())
}



async function main() {  
    EllipsisAdapter = await deployContract()
    console.log("==== swap usdt to usdc in ellipisis pool ====== ")
    await Erc20ToErc20(EllipsisAdapter)
    console.log("==== swap BNB to ZBNB in ellipisis pool ====== ")
    await NativeToErc20(EllipsisAdapter)
    console.log("==== swap ZBNB to BNB in ellipisis pool ====== ")
    await ERC20ToNative(EllipsisAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

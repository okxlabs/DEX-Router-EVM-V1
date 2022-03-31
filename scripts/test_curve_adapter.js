const { ethers } = require("hardhat");
require("./tools");
const { getConfig } = require("./config");
tokenConfig = getConfig("eth");

// 3pool address: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7

// https://etherscan.io/tx/0x13eb2d711be3ae0625b06ea685e2e55e148868fa88494770d61183251ba479bd
// block: 14441279
// 0	i	      int128	2
// 1	j	      int128	0
// 2	dx	    uint256	400100000000
// 3	min_dy	uint256	396190070100000000000000

// 400,100 USDT
// 400,191.991391111620514764 DAI

async function deployContract() {
  CurveAdapter = await ethers.getContractFactory("CurveAdapter");
  CurveAdapter = await CurveAdapter.deploy();
  await CurveAdapter.deployed();
  return CurveAdapter
}

async function execute(CurveAdapter) {
    userAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    therepoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    // DAI
    DaiContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.DAI.baseTokenAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(userAddress);
    console.log("user balance: ", beforeBalance.toString());

    // transfer token
    await USDTContract.connect(signer).transfer(CurveAdapter.address, ethers.utils.parseUnits("6000", 6));
    afterBalance = await USDTContract.balanceOf(CurveAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(CurveAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128", "bool"],
      [
          USDTContract.address,
          DaiContract.address,
          2,
          0,
          false
      ]
    )
    rxResult = await CurveAdapter.sellQuote(
      CurveAdapter.address,
      therepoolAddress,
      moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(CurveAdapter.address);
    usdtBalance = await USDTContract.balanceOf(CurveAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());
}


// ust/ underlying meta pool address: 0x890f4e345b1daed0367a877a1612f86a1f86985f

// https://etherscan.io/tx/0x8ee26ec28fc90e7d4cadd1b86e8232eee60cda014c0a1c64311d6a310a1c53d8
// 0	i	int128	1
// 1	j	int128	0
// 2	dx	uint256	5226196602488890755975
// 3	min_dy	uint256	5164285500000000000000

// 5,221.65  DAI
// 5,216  UST

async function execute_underlying(CurveAdapter) {
  userAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
  USTMETAPoolAddress = "0x890f4e345b1daed0367a877a1612f86a1f86985f"

  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // USDT
  DAIContract = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.DAI.baseTokenAddress
  )

  // DAI
  WUSTContract = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WUST.baseTokenAddress
  )

  // check user token
  beforeBalance = await DAIContract.balanceOf(CurveAdapter.address);
  console.log("DAI  beforebalance: ", beforeBalance.toString());

  // swap
  beforeBalance = await WUSTContract.balanceOf(CurveAdapter.address);
  console.log("WUST beforeBalance: ", beforeBalance.toString());

  moreinfo =  ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "int128", "int128","bool"],
    [
        DAIContract.address,
        WUSTContract.address,
        1,
        0,
        true
    ]
  )
  rxResult = await CurveAdapter.sellQuote(
    CurveAdapter.address,
    USTMETAPoolAddress,
    moreinfo
  );

  // console.log(rxResult)

  daiBalance = await DAIContract.balanceOf(CurveAdapter.address);
  WusdtBalance = await WUSTContract.balanceOf(CurveAdapter.address);
  console.log("DAI afterBalance: ", daiBalance.toString());
  console.log("WUST afterBalance: ", WusdtBalance.toString());
}


async function main() {
  CurveAdapter = await deployContract()
  console.log("===== check 3pool =====")
  await execute(CurveAdapter);
  console.log("==== check meta pool =====")
  await execute_underlying(CurveAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

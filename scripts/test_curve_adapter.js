const { ethers } = require("hardhat");
require("./tools");


// 3pool address: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7

// https://etherscan.io/tx/0x13eb2d711be3ae0625b06ea685e2e55e148868fa88494770d61183251ba479bd
// block: 14441279
// 0	i	      int128	2
// 1	j	      int128	0
// 2	dx	    uint256	400100000000
// 3	min_dy	uint256	396190070100000000000000

// 400,100 USDT
// 400,191.991391111620514764 DAI

async function execute() {
    userAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    USDTAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    DAIAddress= "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    therepoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // 获得
    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy();
    await CurveAdapter.deployed();

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      USDTAddress
    )

    // DAI
    DaiContract = await ethers.getContractAt(
      "MockERC20",
      DAIAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(userAddress);
    console.log("user balance: ", beforeBalance.toString());

    // transfer token
    await USDTContract.connect(signer).transfer(CurveAdapter.address, 1000000000);
    afterBalance = await USDTContract.balanceOf(CurveAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(CurveAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128"],
      [
          USDTAddress,
          DAIAddress,
          2,
          0
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

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

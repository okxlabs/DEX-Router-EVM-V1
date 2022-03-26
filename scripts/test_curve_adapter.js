const { ethers } = require("hardhat");
const fs = require("fs");
const { hrtime } = require("process");
require("./utils");


// 3pool address: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7

// https://etherscan.io/tx/0x13eb2d711be3ae0625b06ea685e2e55e148868fa88494770d61183251ba479bd
// block: 14441279
// 0	i	int128	2
// 1	j	int128	0
// 2	dx	uint256	400100000000
// 3	min_dy	uint256	396190070100000000000000

// 400,100 USDT
// 400,191.991391111620514764 DAI

async function execute() {  
    provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545/");
    UserAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
    UsdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    DAIAddress= "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    therepoolAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"
    await provider.send("hardhat_impersonateAccount",[UserAddress]);

    signer = await provider.getSigner(UserAddress)

    // 获得
    CurveAdapter = await ethers.getContractFactory("CurveAdapter");
    CurveAdapter = await CurveAdapter.deploy();
    await CurveAdapter.deployed();

    // USDT
    usetABI = JSON.parse(fs.readFileSync('./test/adapter/usdt.json', 'utf8'));
    USDTContract = new ethers.Contract(UsdtAddress, usetABI, provider);

    // DAI
    daiABI = JSON.parse(fs.readFileSync('./test/adapter/dai.json', 'utf8'));
    DaiContract = new ethers.Contract(DAIAddress, daiABI, provider);

    // check user token
    beforeBalance = await USDTContract.balanceOf(UserAddress);
    console.log("user balance: ", beforeBalance.toString());

    //transfer token
    beforeBalance = await USDTContract.balanceOf(CurveAdapter.address);
    await USDTContract.connect(signer).transfer(CurveAdapter.address, 1000000000);
    afterBalance = await USDTContract.balanceOf(CurveAdapter.address);

    console.log("USDT beforeBalance: ", beforeBalance.toString());
    console.log("USDT afterBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(CurveAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "int128", "int128"],
      [
          UsdtAddress,
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
    
    console.log(" ===== for debug =====")
    console.log(rxResult)
    console.log(" ===== for debug =====")

    afterBalance = await DaiContract.balanceOf(CurveAdapter.address);
    usdtBalance = await USDTContract.balanceOf(CurveAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());

    console.log("for debug: moreinfo", moreinfo, ", CurveAdapter.address: ", CurveAdapter.address, ", therepoolAddress: ", therepoolAddress);

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

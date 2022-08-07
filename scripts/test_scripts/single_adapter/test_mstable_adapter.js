
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth");

async function deployContract() {
    MstableAdapter = await ethers.getContractFactory("MstableAdapter");
    MstableAdapter = await MstableAdapter.deploy();
    await MstableAdapter.deployed();
    return MstableAdapter
}


// https://etherscan.io/tx/0x3f8fd7bf4101732cf06feebdd2de44cbd7020529cffa3bac0cea934507cb1d2a
// pool: 0xe2f2a5c287993345a840db3b0845fbc70f5935a5

// 0	_input	address	0xdAC17F958D2ee523a2206206994597C13D831ec7
// 1	_output	address	0x6B175474E89094C44Da98b954EedeAC495271d0F
// 2	_inputQuantity	uint256	29390857
// 3	_minOutputQuantity	uint256	29358634975080448726
// 4	_recipient	address	0x865625078FBf045Ba7037ef8781456a9eC0d042a

async function executeMainPool(MstableAdapter) {
    userAddress = "0xed55D1B71b6bfA952ddBC4f24375C91652878560"
    poolAddress = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5"

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
    await USDTContract.connect(signer).transfer(MstableAdapter.address, ethers.utils.parseUnits("500", tokenConfig.tokens.USDT.decimals));
    afterBalance = await USDTContract.balanceOf(MstableAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(MstableAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    const DDL = 2541837122
    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256"],
      [
          USDTContract.address,
          DaiContract.address,
          DDL
      ]
    )
    rxResult = await MstableAdapter.sellQuote(
        MstableAdapter.address,
        poolAddress,
        moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(MstableAdapter.address);
    usdtBalance = await USDTContract.balanceOf(MstableAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());
}

// 0x4eaa01974b6594c0ee62ffd7fee56cf11e6af936
async function executeFeederPool(MstableAdapter) {
    userAddress = "0xed55D1B71b6bfA952ddBC4f24375C91652878560"
    poolAddress = "0x4eaa01974b6594c0ee62ffd7fee56cf11e6af936"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // USDT
    USDTContract = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    // alUSD
    alUSD = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.alUSD.baseTokenAddress
    )

    // check user token
    beforeBalance = await USDTContract.balanceOf(userAddress);
    console.log("user balance: ", beforeBalance.toString());

    // transfer token
    await USDTContract.connect(signer).transfer(MstableAdapter.address, ethers.utils.parseUnits("500", tokenConfig.tokens.USDT.decimals));
    afterBalance = await USDTContract.balanceOf(MstableAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await alUSD.balanceOf(MstableAdapter.address);
    console.log("alUSD beforeBalance: ", beforeBalance.toString());

    const DDL = 2541837122
    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256"],
      [
          USDTContract.address,
          alUSD.address,
          DDL
      ]
    )
    rxResult = await MstableAdapter.sellQuote(
        MstableAdapter.address,
        poolAddress,
         moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(MstableAdapter.address);
    alUSDBalance = await alUSD.balanceOf(MstableAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("alUSD afterBalance: ", alUSDBalance.toString());
}



async function main() {
    MstableAdapter = await deployContract()
    console.log("===== check Main Pool =====")
    await executeMainPool(MstableAdapter);
    console.log("===== check Feeder Pool =====")
    await executeFeederPool(MstableAdapter);


}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });







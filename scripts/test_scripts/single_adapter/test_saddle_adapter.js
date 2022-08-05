const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth");


async function deployContract() {
  SaddleAdapter = await ethers.getContractFactory("SaddleAdapter");
  SaddleAdapter = await SaddleAdapter.deploy();
  await SaddleAdapter.deployed();
  return SaddleAdapter
}

// 0x3911F80530595fBd01Ab1516Ab61255d75AEb066
async function execute(SaddleAdapter) {
    userAddress = "0xed55D1B71b6bfA952ddBC4f24375C91652878560"
    therepoolAddress = "0x3911F80530595fBd01Ab1516Ab61255d75AEb066"

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
    await USDTContract.connect(signer).transfer(SaddleAdapter.address, ethers.utils.parseUnits("1000", 6));
    afterBalance = await USDTContract.balanceOf(SaddleAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(SaddleAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    const is_underlying = false
    const DDL = 2541837122
    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint8", "uint8", "uint256", "bool"],
      [
          USDTContract.address,
          DaiContract.address,
          2,
          0,
          DDL,
          is_underlying
      ]
    )
    rxResult = await SaddleAdapter.sellQuote(
      SaddleAdapter.address,
      therepoolAddress,
      moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(SaddleAdapter.address);
    usdtBalance = await USDTContract.balanceOf(SaddleAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());
}

// pool: 0xB62222B941e9B652BE3632EEa062cb0ff66b1d1c
// SwapToken
// underlyingToken: DAI/USDC/USDT 
async function execute_underlying(SaddleAdapter) {
    userAddress = "0xed55D1B71b6bfA952ddBC4f24375C91652878560"
    therepoolAddress = "0x3911F80530595fBd01Ab1516Ab61255d75AEb066"

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
    await USDTContract.connect(signer).transfer(SaddleAdapter.address, ethers.utils.parseUnits("1000", 6));
    afterBalance = await USDTContract.balanceOf(SaddleAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(SaddleAdapter.address);
    console.log("DAI beforeBalance: ", beforeBalance.toString());

    const is_underlying = true
    const DDL = 2541837122
    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint8", "uint8", "uint256", "bool"],
      [
          USDTContract.address,
          DaiContract.address,
          3,
          1,
          DDL,
          is_underlying
      ]
    )
    rxResult = await SaddleAdapter.sellQuote(
      SaddleAdapter.address,
      therepoolAddress,
      moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(SaddleAdapter.address);
    usdtBalance = await USDTContract.balanceOf(SaddleAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());
}


async function main() {
  SaddleAdapter = await deployContract()
  console.log("===== check basePool =====")
  await execute(SaddleAdapter);
  console.log("===== check metaPool =====")
  await execute(SaddleAdapter);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });



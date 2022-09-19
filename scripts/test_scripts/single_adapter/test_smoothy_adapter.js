const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function deployContract() {
  SmoothyAdapter = await ethers.getContractFactory("SmoothyV1Adapter");
  SmoothyAdapter = await SmoothyAdapter.deploy();
  await SmoothyAdapter.deployed();
  return SmoothyAdapter
}

async function execute(blockNumber, userAddress, network) {
    await setForkNetWorkAndBlockNumber(network, blockNumber);
    await startMockAccount([userAddress]);
    // set account balance 100 eth
    await setBalance(userAddress, ethers.utils.parseEther("100"));

    const tokenConfig = getConfig(network);

    SmoothyAdapter = await deployContract();

    signer = await ethers.getSigner(userAddress);

    // BUSD
    BUSD = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.BUSD.baseTokenAddress
    )
  
    // USDT
    USDT = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDT.baseTokenAddress
    )

    // check user token
    beforeBalance = await USDT.balanceOf(SmoothyAdapter.address);
    console.log("USDT beforeBalance: ", beforeBalance.toString());

    // transfer token
    await USDT.connect(signer).transfer(SmoothyAdapter.address, ethers.utils.parseUnits("100", 6));

    afterBalance = await USDT.balanceOf(SmoothyAdapter.address);
    console.log("USDT afterBalance: ", afterBalance.toString());

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256", "uint256"],
      [
        USDT.address,
        BUSD.address,
        0,
        5
      ]
    )
    rxResult = await SmoothyAdapter.connect(signer).sellQuote(
      SmoothyAdapter.address,
      ethers.constants.AddressZero,
      moreinfo
    );
    // console.log(rxResult)

    afterBalance = await BUSD.balanceOf(SmoothyAdapter.address);
    usdtBalance = await USDT.balanceOf(SmoothyAdapter.address);
    console.log("BUSD afterBalance: ", afterBalance.toString());
    console.log("USDT afterBalance: ", usdtBalance.toString());
}

async function main() {
  // Banance 8 Address
  userAddress = "0xF977814e90dA44bFA03b6295A0616a897441aceC"
  await execute(
    15495850,
    userAddress,
    "eth"
  );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

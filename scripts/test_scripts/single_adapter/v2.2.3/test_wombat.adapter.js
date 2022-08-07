
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("bsc");

async function deployContract() {
    WombatAdapter = await ethers.getContractFactory("WombatAdapter");
    WombatAdapter = await WombatAdapter.deploy();
    await WombatAdapter.deployed();
    return WombatAdapter
}

// https://bscscan.com/address/0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0#writeProxyContract
async function executeUsdPool(WombatAdapter) {
    userAddress = "0xed55D1B71b6bfA952ddBC4f24375C91652878560"
    therepoolAddress = "0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0"

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
    await USDTContract.connect(signer).transfer(ShellAdapter.address, ethers.utils.parseUnits("500", tokenConfig.tokens.USDT.decimals));
    afterBalance = await USDTContract.balanceOf(ShellAdapter.address);

    console.log("USDT beforeBalance: ", afterBalance.toString());

    // swap
    beforeBalance = await DaiContract.balanceOf(ShellAdapter.address);
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
    rxResult = await ShellAdapter.sellQuote(
        ShellAdapter.address,
        therepoolAddress,
        moreinfo
    );

    // console.log(rxResult)

    afterBalance = await DaiContract.balanceOf(ShellAdapter.address);
    usdtBalance = await USDTContract.balanceOf(ShellAdapter.address);
    console.log("USDT afterBalance: ", usdtBalance.toString());
    console.log("DAI afterBalance: ", afterBalance.toString());
}




async function main() {
    ShellAdapter = await deployContract()
    console.log("===== check usd Pool =====")
    await executeUsdPool(ShellAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });



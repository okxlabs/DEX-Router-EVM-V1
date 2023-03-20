const { ethers } = require("hardhat");
require("../../tools");

async function deployContract() {
    FraxswapAdapter = await ethers.getContractFactory("FraxswapAdapter");
    FraxswapAdapter = await FraxswapAdapter.deploy();
    await FraxswapAdapter.deployed();
    return FraxswapAdapter
}

// Pool: 0x03B59Bd1c8B9F6C265bA0c3421923B93f15036Fa
// Token0: Frax (0x853d955aCEf822Db058eb8505911ED77F175b99e)
// Token1: FXS (0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0)
// Frax => FXS: 


async function execute(FraxswapAdapter) {
    userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"
    poolAddress = "0x03B59Bd1c8B9F6C265bA0c3421923B93f15036Fa"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // Quote Token
    Frax = await ethers.getContractAt(
      "MockERC20",
      "0x853d955aCEf822Db058eb8505911ED77F175b99e"
    )

    // Base Token
    Fxs = await ethers.getContractAt(
      "MockERC20",
      "0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0"
    )

    // check user token
    beforeBalance = await Frax.balanceOf(userAddress);
    console.log("user balance: ", beforeBalance.toString());
    
    fromAmount = ethers.utils.parseEther("100")

    // transfer token
    await Frax.connect(signer).transfer(poolAddress, fromAmount);
     
    // swap
    beforeBalance = await Fxs.balanceOf(FraxswapAdapter.address);
    console.log("Fxs beforeBalance: ", beforeBalance.toString());

    rxResult = await FraxswapAdapter.sellQuote(
        signer.address,
        poolAddress,
        moreInfo
    );

    // console.log(rxResult)

    FxsBalance = await Fxs.balanceOf(signer.address);
    console.log("Fxs afterBalance: ", FxsBalance.toString());

    // ================== SellBase ==================
    await Fxs.connect(signer).transfer(poolAddress, await Fxs.balanceOf(signer.address));

    rxResult = await FraxswapAdapter.sellBase(
      signer.address,
      poolAddress,
      moreInfo
  );
  console.log("================== SellBase ==================")
  FraxBalance = await Frax.balanceOf(signer.address);
  console.log("Frax afterBalance: ", FraxBalance.toString());
  FxsBalance = await Fxs.balanceOf(signer.address);
  console.log("Fxs afterBalance: ", FxsBalance.toString());

}


async function main() {
    FraxswapAdapter = await deployContract()
    console.log("===== FraxswapAdapter =====")
    await execute(FraxswapAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

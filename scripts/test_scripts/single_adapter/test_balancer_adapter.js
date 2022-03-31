const { ethers } = require("hardhat");
require("../../tools");
require("../../config");

async function executeWETH2AAVE() {
  config = getConfig("eth")

  // Network Main
  await setForkBlockNumber(14436484);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  WETH = await ethers.getContractAt(
    "MockERC20",
    config.token.WETH
  )
  AAVE = await ethers.getContractAt(
    "MockERC20",
    config.token.AAVE
  )

  BalancerAdapter = await ethers.getContractFactory("BalancerAdapter");
  balancerAdapter = await BalancerAdapter.deploy();
  await balancerAdapter.deployed();

  // transfer 100 WETH to balancerAdapter
  await WETH.connect(account).transfer(balancerAdapter.address, ethers.utils.parseEther('3.5'));

  console.log("before WETH Balance: " + await WETH.balanceOf(balancerAdapter.address));
  console.log("before AAVE Balance: " + await AAVE.balanceOf(account.address));

  // WETH to LPAL token pool vault
  rxResult = await balancerAdapter.sellBase(
    account.address,                                // receive token address
    "0xc697051d1c6296c24ae3bcef39aca743861d9a81",   // AAVE-WETH Pool
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address"],
      [
        WETH.address,                               // from token address 
        AAVE.address                                // to token address
      ]
    )
  );
  // console.log(rxResult);

  console.log("after WETH Balance: " + await WETH.balanceOf(balancerAdapter.address));
  console.log("after AAVE Balance: " + await AAVE.balanceOf(account.address));
}

async function main() {
  await executeWETH2AAVE();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

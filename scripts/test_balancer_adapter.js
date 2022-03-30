const { ethers } = require("hardhat");
require("./tools");
const {getConfig} = require("./config");
tokenConfig = getConfig("eth")

async function executeWETH2AAVE() {

  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  WETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  
  AAVE = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.AAVE.baseTokenAddress
  )

  balancerAdapter = await ethers.getContractFactory("BalancerAdapter");
  balancerAdapter = await balancerAdapter.deploy();
  await balancerAdapter.deployed();

  // transfer 100 WETH to bancorAdapter
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

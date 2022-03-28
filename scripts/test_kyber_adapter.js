const { ethers } = require("hardhat");
require("./tools");

async function executeWETH2USDT() {
  // Network Main
  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  WETH = await ethers.getContractAt(
    "MockERC20",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
  )
  USDT = await ethers.getContractAt(
    "MockERC20",
    "0xdac17f958d2ee523a2206206994597c13d831ec7"
  )

  KyberAdapter = await ethers.getContractFactory("KyberAdapter");
  kyberAdapter = await KyberAdapter.deploy();
  await kyberAdapter.deployed();
  
  const poolAddr = "0xcE9874C42DcE7fffbE5E48B026Ff1182733266Cb";

  console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
  console.log("before USDT Balance: " + await USDT.balanceOf(account.address));

  // transfer 3.5 WETH to poolAddr
  await WETH.connect(account).transfer(poolAddr, ethers.utils.parseEther('3.5'));

  // WETH to USDT token pool
  rxResult = await kyberAdapter.sellBase(
    account.address,                                // receive token address
    poolAddr,                                       // WETH-USDT Pool
    "0x"
  );
  // console.log(rxResult);

  console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
  console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
  
  // transfer 1000 USDT to poolAddr
  await USDT.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1000', 6));

  // USDT to WETH token pool
  rxResult = await kyberAdapter.sellQuote(
    account.address,                                // receive token address
    poolAddr,                                       // WETH-USDT Pool
    "0x"
  );
  // console.log(rxResult);

  console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
  console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
}

async function main() {
  await executeWETH2USDT();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER } = require("./utils")

async function executeWETH2AAVE() {
  let pmmReq = []
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

  const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

  balancerAdapter = await ethers.getContractFactory("BalancerAdapter");
  balancerAdapter = await balancerAdapter.deploy();
  await balancerAdapter.deployed();

  // transfer 100 WETH to bancorAdapter
  // await WETH.connect(account).transfer(balancerAdapter.address, ethers.utils.parseEther('3.5'));
  const fromTokenAmount = ethers.utils.parseEther('3.5');
  const minReturnAmount = 0;
  const deadLine = FOREVER;
  const balancerPoolAddr = "0xc697051d1c6296c24ae3bcef39aca743861d9a81"; // AAVE-WETH Pool
  console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
  console.log("before AAVE Balance: " + await AAVE.balanceOf(account.address));

  // node1
  // const requestParam1 = [
  //   tokenConfig.tokens.WETH.baseTokenAddress,
  //   [fromTokenAmount]
  // ];
  const mixAdapter1 = [
    balancerAdapter.address
  ];
  const assertTo1 = [
    balancerAdapter.address
  ];
  const weight1 = Number(10000).toString(16).replace('0x', '');
  const rawData1 = [
    "0x" + 
    direction(tokenConfig.tokens.AAVE.baseTokenAddress, tokenConfig.tokens.AAVE.baseTokenAddress) + 
    "0000000000000000000" + 
    weight1 + 
    balancerPoolAddr.replace("0x", "")  // AAVE-WETH Pool
  ];
  const moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address"],
    [
      WETH.address,                               // from token address 
      AAVE.address                                // to token address
    ]
  )
  const extraData1 = [moreInfo];
  const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];
  
  // layer1
  // const request1 = [requestParam1];
  const layer1 = [router1];

  const baseRequest = [
    WETH.address,
    AAVE.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ]
  await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
  await dexRouter.connect(account).smartSwap(
    baseRequest,
    [fromTokenAmount],
    [layer1],
    pmmReq
  );

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

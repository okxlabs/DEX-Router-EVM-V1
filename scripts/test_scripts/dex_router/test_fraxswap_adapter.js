const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, direction, FOREVER } = require("./utils")

async function deployContract() {
    FraxswapAdapter = await ethers.getContractFactory("FraxswapAdapter");
    FraxswapAdapter = await FraxswapAdapter.deploy();
    await FraxswapAdapter.deployed();
    return FraxswapAdapter
}

async function executeSellQuote(FraxswapAdapter) {
    pmmReq = []
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
    beforeBalance = await Fxs.balanceOf(userAddress);
    console.log("user before balance: ", beforeBalance.toString());
    
    fromTokenAmount = ethers.utils.parseEther("100")

    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [
        FraxswapAdapter.address
    ];
    let assertTo1 = [
        poolAddress
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" +
        direction(Frax.address, Fxs.address) +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")
    ];

    let moreInfo = "0x";
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, Frax.address];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        Frax.address,
        Fxs.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    await Frax.connect(signer).approve(tokenApprove.address, fromTokenAmount);
    let tx = await dexRouter.connect(signer).smartSwap(
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
    let gasCost = await getTransactionCost(tx);
    console.log(gasCost);

    FxsBalance = await Fxs.balanceOf(signer.address);
    console.log("Fxs afterBalance: ", FxsBalance.toString());
    console.log("change >>> ", (FxsBalance - beforeBalance).toString());

}

async function executeSellBase(FraxswapAdapter) {
  pmmReq = []
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
  console.log("user before balance: ", beforeBalance.toString());
  
  fromTokenAmount = ethers.utils.parseEther("100")

  let { dexRouter, tokenApprove } = await initDexRouter();

  let minReturnAmount = 0;
  let deadLine = FOREVER;
  let mixAdapter1 = [
      FraxswapAdapter.address
  ];
  let assertTo1 = [
      poolAddress
  ];
  let weight1 = Number(10000).toString(16).replace('0x', '');
  let rawData1 = [
      "0x" +
      direction(Fxs.address, Frax.address) +
      "0000000000000000000" +
      weight1 +
      poolAddress.replace("0x", "")
  ];

  let moreInfo = "0x";
  let extraData1 = [moreInfo];
  let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, Fxs.address];

  // layer1
  // let request1 = [requestParam1];
  let layer1 = [router1];

  let baseRequest = [
      Fxs.address,
      Frax.address,
      fromTokenAmount,
      minReturnAmount,
      deadLine,
  ]

  await Fxs.connect(signer).approve(tokenApprove.address, fromTokenAmount);
  let tx = await dexRouter.connect(signer).smartSwap(
      baseRequest,
      [fromTokenAmount],
      [layer1],
      pmmReq
  );
  let gasCost = await getTransactionCost(tx);
  console.log(gasCost);

  FraxBalance = await Frax.balanceOf(signer.address);
  console.log("Frax afterBalance: ", FraxBalance.toString());
  console.log("change >>> ", (FraxBalance - beforeBalance).toString());

}



const getTransactionCost = async (txResult) => {
  const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
  return ethers.BigNumber.from(cumulativeGasUsed);
};

async function main() {
    FraxswapAdapter = await deployContract()
    console.log("===== executeSellQuote =====")
    await executeSellQuote(FraxswapAdapter);

    console.log("===== executeSellBase =====")
    await executeSellBase(FraxswapAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
require("../../../tools");
const { initDexRouter, direction, FOREVER } = require("../utils")
const { getConfig } = require("../../../config");
tokenConfig = getConfig("eth")

async function deployContract() {
    FraxswapAdapter = await ethers.getContractFactory("FraxswapAdapter");
    FraxswapAdapter = await FraxswapAdapter.deploy();
    await FraxswapAdapter.deployed();
    return FraxswapAdapter
}

async function executeSellBase(FraxswapAdapter) {
    pmmReq = []
    userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"
    poolAddress = "0x31351bf3fba544863fbff44ddc27ba880916a199"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // Base Token
    Frax = await ethers.getContractAt(
      "MockERC20",
      "0x853d955aCEf822Db058eb8505911ED77F175b99e"
    )

    WETH = await ethers.getContractAt(
      "MockERC20",
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    )

    // check user token
    beforeBalance = await WETH.balanceOf(userAddress);
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
        direction(Frax.address, WETH.address) +
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
        WETH.address,
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

    wethBalance = await WETH.balanceOf(signer.address);
    console.log("weth afterBalance: ", wethBalance.toString());
    console.log("change >>> ", (wethBalance    - beforeBalance).toString());
}

async function executeSellQuote(FraxswapAdapter) {
  pmmReq = []
  userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"
  poolAddress = "0x31351bf3fba544863fbff44ddc27ba880916a199"

  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // Base Token
  Frax = await ethers.getContractAt(
    "MockERC20",
    "0x853d955aCEf822Db058eb8505911ED77F175b99e"
  )

  WETH = await ethers.getContractAt(
    "MockERC20",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
  )

  // check user token
  beforeBalance = await Frax.balanceOf(userAddress);
  console.log("user before balance: ", beforeBalance.toString());
  
  fromTokenAmount =  await WETH.balanceOf(userAddress);

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
      direction(WETH.address, Frax.address) +
      "0000000000000000000" +
      weight1 +
      poolAddress.replace("0x", "")
  ];

  let moreInfo = "0x";
  let extraData1 = [moreInfo];
  let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];

  // layer1
  // let request1 = [requestParam1];
  let layer1 = [router1];

  let baseRequest = [
      WETH.address,
      Frax.address,
      fromTokenAmount,
      minReturnAmount,
      deadLine,
  ]

  await WETH.connect(signer).approve(tokenApprove.address, fromTokenAmount);
  let tx = await dexRouter.connect(signer).smartSwap(
      baseRequest,
      [fromTokenAmount],
      [layer1],
      pmmReq
  );
  let gasCost = await getTransactionCost(tx);
  console.log(gasCost);

  fraxBalance = await Frax.balanceOf(signer.address);
  console.log("frax afterBalance: ", fraxBalance.toString());
  console.log("change >>> ", (fraxBalance  - beforeBalance).toString());
}



const getTransactionCost = async (txResult) => {
  const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
  return ethers.BigNumber.from(cumulativeGasUsed);
};

async function main() {
    FraxswapAdapter = await deployContract()
    console.log("===== executeSellQuote =====")
    await executeSellBase(FraxswapAdapter);


    console.log("===== FraxswapAdapter =====")
    await executeSellQuote(FraxswapAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
require("../../tools");
const { initDexRouter, direction, FOREVER } = require("./utils")
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")

// address weth,
// address frxETHMinter,
// address sfrxETH,
// address frxETH
async function deployContract() {
    fraxETHAdapter = await ethers.getContractFactory("fraxETHAdapter");
    fraxETHAdapter = await fraxETHAdapter.deploy(
      tokenConfig.tokens.WETH.baseTokenAddress,
      "0xbAFA44EFE7901E04E39Dad13167D089C559c1138", //frxETHMinter
      "0xac3E018457B222d93114458476f3E3416Abbe38F", //sfrxETH
      "0x5E8422345238F34275888049021821E8E08CAa1f" //frxETH
    );
    await fraxETHAdapter.deployed();
    return fraxETHAdapter
}

async function eth_to_fraxeth(FraxswapAdapter) {
    pmmReq = []
    userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"

    // useless
    poolAddress = "0x31351bf3fba544863fbff44ddc27ba880916a199"

    startMockAccount([userAddress]);

    signer = await ethers.getSigner(userAddress);

    // Base Token
    FromToken = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.ETH.baseTokenAddress
    )

    toToken = await ethers.getContractAt(
      "MockERC20",
      "0x5E8422345238F34275888049021821E8E08CAa1f"
    )

    // check user token
    beforeBalance = await toToken.balanceOf(userAddress);
    console.log("user before balance: ", beforeBalance.toString());
    
    fromTokenAmount = ethers.utils.parseEther("0.1")

    let { dexRouter, tokenApprove } = await initDexRouter();

    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [
        FraxswapAdapter.address
    ];
    let assertTo1 = [
        FraxswapAdapter.address
    ];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" +
        direction(FromToken.address, toToken.address) +
        "0000000000000000000" +
        weight1 +
        poolAddress.replace("0x", "")
    ];

    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
      ["uint8"],
      [
          0
      ]
    )    
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, tokenConfig.tokens.WETH.baseTokenAddress];

    // layer1
    // let request1 = [requestParam1];
    let layer1 = [router1];

    let baseRequest = [
        FromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]

    // await FromToken.connect(signer).approve(tokenApprove.address, fromTokenAmount);
    let tx = await dexRouter.connect(signer).smartSwapByOrderId(
        0,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
        {
          value: fromTokenAmount
        }
    );
    let gasCost = await getTransactionCost(tx);
    console.log(gasCost);

    wethBalance = await toToken.balanceOf(signer.address);
    console.log("toToken afterBalance: ", wethBalance.toString());
    console.log("change >>> ", (wethBalance    - beforeBalance).toString());
}

async function fraxeth_to_sfrxeth(FraxswapAdapter) {
  pmmReq = []
  userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"

  // useless
  poolAddress = "0x31351bf3fba544863fbff44ddc27ba880916a199"

  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // Base Token
  FromToken = await ethers.getContractAt(
    "MockERC20",
    "0x5E8422345238F34275888049021821E8E08CAa1f"
  )

  toToken = await ethers.getContractAt(
    "MockERC20",
    "0xac3E018457B222d93114458476f3E3416Abbe38F"
  )

  // check user token
  beforeBalance = await toToken.balanceOf(userAddress);
  console.log("user before balance: ", beforeBalance.toString());
  
  fromTokenAmount = await FromToken.balanceOf(userAddress)

  let { dexRouter, tokenApprove } = await initDexRouter();

  let minReturnAmount = 0;
  let deadLine = FOREVER;
  let mixAdapter1 = [
      FraxswapAdapter.address
  ];
  let assertTo1 = [
      FraxswapAdapter.address
  ];
  let weight1 = Number(10000).toString(16).replace('0x', '');
  let rawData1 = [
      "0x" +
      direction(FromToken.address, toToken.address) +
      "0000000000000000000" +
      weight1 +
      poolAddress.replace("0x", "")
  ];

  let moreInfo =  ethers.utils.defaultAbiCoder.encode(
    ["uint8"],
    [
        1
    ]
  )    
  let extraData1 = [moreInfo];
  let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, FromToken.address];

  // layer1
  // let request1 = [requestParam1];
  let layer1 = [router1];

  let baseRequest = [
      FromToken.address,
      toToken.address,
      fromTokenAmount,
      minReturnAmount,
      deadLine,
  ]

  await FromToken.connect(signer).approve(tokenApprove.address, fromTokenAmount);
  let tx = await dexRouter.connect(signer).smartSwapByOrderId(
      0,
      baseRequest,
      [fromTokenAmount],
      [layer1],
      pmmReq,
      {
        value: fromTokenAmount
      }
  );
  let gasCost = await getTransactionCost(tx);
  console.log(gasCost);

  wethBalance = await toToken.balanceOf(signer.address);
  console.log("toToken afterBalance: ", wethBalance.toString());
  console.log("change >>> ", (wethBalance    - beforeBalance).toString());
}

async function sfrxeth_to_fraxeth(FraxswapAdapter) {
  pmmReq = []
  userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"

  // useless
  poolAddress = "0x31351bf3fba544863fbff44ddc27ba880916a199"

  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // Base Token
  FromToken = await ethers.getContractAt(
    "MockERC20",
    "0xac3E018457B222d93114458476f3E3416Abbe38F"
  )

  toToken = await ethers.getContractAt(
    "MockERC20",
    "0x5E8422345238F34275888049021821E8E08CAa1f"
  )

  // check user token
  beforeBalance = await toToken.balanceOf(userAddress);
  console.log("user before balance: ", beforeBalance.toString());
  
  fromTokenAmount = await FromToken.balanceOf(userAddress)

  let { dexRouter, tokenApprove } = await initDexRouter();

  let minReturnAmount = 0;
  let deadLine = FOREVER;
  let mixAdapter1 = [
      FraxswapAdapter.address
  ];
  let assertTo1 = [
      FraxswapAdapter.address
  ];
  let weight1 = Number(10000).toString(16).replace('0x', '');
  let rawData1 = [
      "0x" +
      direction(FromToken.address, toToken.address) +
      "0000000000000000000" +
      weight1 +
      poolAddress.replace("0x", "")
  ];

  let moreInfo =  ethers.utils.defaultAbiCoder.encode(
    ["uint8"],
    [
        2
    ]
  )    
  let extraData1 = [moreInfo];
  let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, FromToken.address];

  // layer1
  // let request1 = [requestParam1];
  let layer1 = [router1];

  let baseRequest = [
      FromToken.address,
      toToken.address,
      fromTokenAmount,
      minReturnAmount,
      deadLine,
  ]

  await FromToken.connect(signer).approve(tokenApprove.address, fromTokenAmount);
  let tx = await dexRouter.connect(signer).smartSwapByOrderId(
      0,
      baseRequest,
      [fromTokenAmount],
      [layer1],
      pmmReq,
      {
        value: fromTokenAmount
      }
  );
  let gasCost = await getTransactionCost(tx);
  console.log(gasCost);

  wethBalance = await toToken.balanceOf(signer.address);
  console.log("toToken afterBalance: ", wethBalance.toString());
  console.log("change >>> ", (wethBalance    - beforeBalance).toString());
}

async function eth_to_sfraxeth(FraxswapAdapter) {
  pmmReq = []
  userAddress = "0x3af7fa91f0b2b2d148622831e3a21c165c8c8e49"

  // useless
  poolAddress = "0x31351bf3fba544863fbff44ddc27ba880916a199"

  startMockAccount([userAddress]);

  signer = await ethers.getSigner(userAddress);

  // Base Token
  FromToken = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.ETH.baseTokenAddress
  )

  toToken = await ethers.getContractAt(
    "MockERC20",
    "0xac3E018457B222d93114458476f3E3416Abbe38F"
  )

  // check user token
  beforeBalance = await toToken.balanceOf(userAddress);
  console.log("user before balance: ", beforeBalance.toString());
  
  fromTokenAmount = ethers.utils.parseEther("0.1")

  let { dexRouter, tokenApprove } = await initDexRouter();

  let minReturnAmount = 0;
  let deadLine = FOREVER;
  let mixAdapter1 = [
      FraxswapAdapter.address
  ];
  let assertTo1 = [
      FraxswapAdapter.address
  ];
  let weight1 = Number(10000).toString(16).replace('0x', '');
  let rawData1 = [
      "0x" +
      direction(FromToken.address, toToken.address) +
      "0000000000000000000" +
      weight1 +
      poolAddress.replace("0x", "")
  ];

  let moreInfo =  ethers.utils.defaultAbiCoder.encode(
    ["uint8"],
    [
        3
    ]
  )    
  let extraData1 = [moreInfo];
  let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, tokenConfig.tokens.WETH.baseTokenAddress];

  // layer1
  // let request1 = [requestParam1];
  let layer1 = [router1];

  let baseRequest = [
      FromToken.address,
      toToken.address,
      fromTokenAmount,
      minReturnAmount,
      deadLine,
  ]

  // await FromToken.connect(signer).approve(tokenApprove.address, fromTokenAmount);
  let tx = await dexRouter.connect(signer).smartSwapByOrderId(
      0,
      baseRequest,
      [fromTokenAmount],
      [layer1],
      pmmReq,
      {
        value: fromTokenAmount
      }
  );
  let gasCost = await getTransactionCost(tx);
  console.log(gasCost);

  wethBalance = await toToken.balanceOf(signer.address);
  console.log("toToken afterBalance: ", wethBalance.toString());
  console.log("change >>> ", (wethBalance    - beforeBalance).toString());
}
const getTransactionCost = async (txResult) => {
  const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
  return ethers.BigNumber.from(cumulativeGasUsed);
};

async function main() {
    FraxswapAdapter = await deployContract()
    console.log("===== eth_to_fraxeth =====")
    await eth_to_fraxeth(FraxswapAdapter);

    console.log("===== fraxeth_to_sfrxeth =====")
    await fraxeth_to_sfrxeth(FraxswapAdapter);

    console.log("===== sfrxeth_to_fraxeth =====")
    await sfrxeth_to_fraxeth(FraxswapAdapter);

    console.log("===== eth_to_sfraxeth =====")
    await eth_to_sfraxeth(FraxswapAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

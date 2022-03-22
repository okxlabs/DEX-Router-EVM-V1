const { ethers } = require("hardhat");
const { deployed } = require("./deployed");

async function main() {  
  usdt = await ethers.getContractAt(
    'MockERC20',
    deployed.tokens.usdt
  )
  weth = await ethers.getContractAt(
    "MockERC20",
    deployed.tokens.weth
  )
  wbnb = await ethers.getContractAt(
    "MockERC20",
    deployed.tokens.wbnb
  )
  dot = await ethers.getContractAt(
    "MockERC20",
    deployed.tokens.dot
  )
  tokenApprove = await ethers.getContractAt(
    "TokenApprove",
    deployed.base.tokenApprove
  );
  dexRouter = await ethers.getContractAt(
    "DexRouteProxy",
    deployed.base.dexRouter
  );

  fromToken = usdt;
  toToken = wbtc;
  fromTokenAmount = ethers.utils.parseEther('0.79374371');
  minReturnAmount = ethers.utils.parseEther('0');
  deadLine = 2000000000;

  const baseRequest = [
    fromToken.address,
    toToken.address,
    fromTokenAmount,
    minReturnAmount,
    deadLine,
  ]

  layersAmount = [];
  data = []

  // r = await wbnb.approve(tokenApprove.address, ethers.utils.parseEther('100000000'));
  // console.log(r);

  r = await dexRouter.smartSwap(
    baseRequest,
    layersAmount,
    data[0],
    data[1]
  );
  console.log("" + r)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
const deployed = require('./deployed');

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
  tokenApproveProxy = await ethers.getContractAt(
    "TokenApproveProxy",
    deployed.base.tokenApproveProxy
  );
  dexRouter = await ethers.getContractAt(
    "DexRouter",
    deployed.base.dexRouter
  );

  // await wbnb.approve(tokenApprove.address, ethers.constants.MaxUint256);
  
  // case 1 PASS
  // data = {
  //   amount: "100000000000000000",
  //   minReturn: "24401378644391401",
  //   pools: [
  //       "0x00000000000000003b6d03402905817b020fd35d9d09672946362b62766f0d69"
  //   ],
  //   srcToken: "0x55d398326f99059ff775485246999027b3197955"
  // }

  // case 2 PASS BNB -> USDT
  // data = {
  //   amount: "100000000000000000",
  //   minReturn: "0",
  //   pools: [
  //       "0x80000000000000003b8b87c08840c6252e2e86e545defb6da98b2a0e26d8c1ba"
  //   ],
  //   srcToken: "0x0000000000000000000000000000000000000000"
  // }

  // case 3
  data = {
    amount: "100000000000000000",
    minReturn: "0",
    pools: [
        "0x40000000000000003b6d03402905817b020fd35d9d09672946362b62766f0d69"
    ],
    srcToken: "0x55d398326f99059ff775485246999027b3197955"
  }
  // case4 pass
  // data = {
  //   amount: "100000000000000000",
  //   minReturn: "0",
  //   pools: [
  //       "0x80000000000000003b74a460f6f5ce9a91dd4fae2d2ed92e25f2a4dc8564f174"
  //   ],
  //   srcToken: "0x55d398326f99059ff775485246999027b3197955"
  // }
  r = await dexRouter.unxswap(
    data.srcToken,
    data.amount,
    data.minReturn,
    data.pools,
    {
      // gasLimit: 500000
    }
  );
  console.log(r)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

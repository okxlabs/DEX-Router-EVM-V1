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
  shib = await ethers.getContractAt(
    "MockERC20",
    deployed.tokens.shib
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

  // case 3 PASS
  // data = {
  //   amount: "100000000000000000",
  //   minReturn: "0",
  //   pools: [
  //       "0x40000000000000003b6d03402905817b020fd35d9d09672946362b62766f0d69"
  //   ],
  //   srcToken: "0x55d398326f99059ff775485246999027b3197955"
  // }

  // case4 PASS
  // data = {
  //   amount: "100000000000000000",
  //   minReturn: "0",
  //   pools: [
  //       "0x80000000000000003b74a460f6f5ce9a91dd4fae2d2ed92e25f2a4dc8564f174"
  //   ],
  //   srcToken: "0x55d398326f99059ff775485246999027b3197955"
  // }

  // case5 PASS
  data = {
    "amount": "100000000000000000000000",
    "minReturn": "31152569945948133",
    "pools": [
        "0x00000000000000003b6d03403d5fc47bfa9afb772dd49daf98f5f4ca994d6fc9",
        "0x80000000000000003b6d034038153dae67b364dc2639717b5458461598762e0a",
        "0x80000000000000003b6d034074c4da0daca1a9e52faec732d96bc7dea9fb3ac1"
    ],
    "srcToken": "0x2859e4544c4bb03966803b044a93563bd2d0dd4d"
  }

  // await shib.approve(tokenApprove.address, ethers.constants.MaxUint256);
  r = await dexRouter.unxswap(
    data.srcToken,
    data.amount,
    data.minReturn,
    data.pools,
    {
      // value: ethers.utils.parseEther('1')
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

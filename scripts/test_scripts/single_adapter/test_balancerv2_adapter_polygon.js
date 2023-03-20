const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("polygon");

const VaultAddress = "0xBA12222222228d8Ba445958a75a0704d566BF2C8"

async function deployContract() {
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    BalancerV2Adapter = await BalancerV2Adapter.deploy( VaultAddress, tokenConfig.tokens.WETH.baseTokenAddress);
    await BalancerV2Adapter.deployed();
    return BalancerV2Adapter
}

// https://polygonscan.com/address/0xD5D7bc115B32ad1449C6D0083E43C87be95F2809
// poolId: 0xd5d7bc115b32ad1449c6d0083e43c87be95f2809000100000000000000000033
// Tokens: (USDC) 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, (WETH) 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, (TEL) 0xdF7837DE1F2Fa4631D716CF2502f8b230F1dcc32

async function checkWeightPool(BalancerV2Adapter) {

    const poolID = "0xd5d7bc115b32ad1449c6d0083e43c87be95f2809000100000000000000000033"
    const accountAddress = "0xF74796Ee9cbb6D5ADeCF940b5C6512fD7c0aa10B";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress
    )
    TEL = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.TEL.baseTokenAddress
    )

    // transfer 1 WETH to bancorAdapter
    await WETH.connect(account).transfer(BalancerV2Adapter.address, ethers.utils.parseEther('1'));

    console.log("before WETH Balance: " + await WETH.balanceOf(BalancerV2Adapter.address));
    console.log("before TEL Balance: " + await TEL.balanceOf(account.address));

    // WETH to LPAL token pool vault
    rxResult = await BalancerV2Adapter.sellBase(
      account.address,                                // receive token address
      VaultAddress,                                  // balancer v2 vault address
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes32"],
        [
          WETH.address,                               // from token address 
          TEL.address,                               // to token address
          poolID  // pool id
        ]
      )
    );
    // console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(BalancerV2Adapter.address));
    console.log("after TEL Balance: " + await TEL.balanceOf(account.address));
}




async function main() {
    BalancerV2Adapter = await deployContract()
    console.log("====== checkWeightPool =====")
    await checkWeightPool(BalancerV2Adapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

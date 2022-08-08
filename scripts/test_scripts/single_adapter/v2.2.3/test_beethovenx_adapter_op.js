const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("../../../tools");
const { getConfig } = require("../../../config");
tokenConfig = getConfig("op");

const VaultAddress = "0xBA12222222228d8Ba445958a75a0704d566BF2C8"

async function deployContract() {
    BeethovenxAdapter = await ethers.getContractFactory("BeethovenxAdapter");
    BeethovenxAdapter = await BeethovenxAdapter.deploy( VaultAddress, tokenConfig.tokens.WETH.baseTokenAddress);
    await BeethovenxAdapter.deployed();
    return BeethovenxAdapter
}

// https://optimistic.etherscan.io/address/0x39965c9dAb5448482Cf7e002F583c812Ceb53046#code
// poolId: 0x39965c9dab5448482cf7e002f583c812ceb53046000100000000000000000003
// Tokens: (WETH) 0x4200000000000000000000000000000000000006,(OP) 0x4200000000000000000000000000000000000042, (USDC) 0x7F5c764cBc14f9669B88837ca1490cCa17c31607

async function checkWeightPool(BeethovenxAdapter) {

    const poolID = "0x39965c9dab5448482cf7e002f583c812ceb53046000100000000000000000003"
    const accountAddress = "0xb589969d38ce76d3d7aa319de7133bc9755fd840";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress
    )
    OP = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.OP.baseTokenAddress
    )

    // transfer 1 WETH to bancorAdapter
    await WETH.connect(account).transfer(BeethovenxAdapter.address, ethers.utils.parseEther('1'));

    console.log("before WETH Balance: " + await WETH.balanceOf(BeethovenxAdapter.address));
    console.log("before OP Balance: " + await OP.balanceOf(account.address));

    // WETH to LPAL token pool vault
    rxResult = await BeethovenxAdapter.sellBase(
      account.address,                                // receive token address
      VaultAddress,                                  // balancer v2 vault address
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes32"],
        [
          WETH.address,                               // from token address 
          OP.address,                               // to token address
          poolID  // pool id
        ]
      )
    );
    // console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(BeethovenxAdapter.address));
    console.log("after OP Balance: " + await OP.balanceOf(account.address));
}




async function main() {
    BeethovenxAdapter = await deployContract()
    console.log("====== checkWeightPool =====")
    await checkWeightPool(BeethovenxAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

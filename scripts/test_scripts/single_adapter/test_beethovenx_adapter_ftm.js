const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("ftm");

const VaultAddress = "0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce"

async function deployContract() {
    BeethovenxAdapter = await ethers.getContractFactory("BeethovenxAdapter");
    BeethovenxAdapter = await BeethovenxAdapter.deploy( VaultAddress, tokenConfig.tokens.WETH.baseTokenAddress);
    await BeethovenxAdapter.deployed();
    return BeethovenxAdapter
}

// https://ftmscan.com/address/0xeCAa1cBd28459d34B766F9195413Cb20122Fb942#code
// poolId: 0xecaa1cbd28459d34b766f9195413cb20122fb942000200000000000000000120
// Tokens: (USDC) 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75, (DAI) 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E

async function checkStablePool(BeethovenxAdapter) {

    const poolID = "0xecaa1cbd28459d34b766f9195413cb20122fb942000200000000000000000120"
    const accountAddress = "0xfcd63662a48d2e802deef6371b3a9fb1917e3c58";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    USDC = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress
    )
    DAI = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.DAI.baseTokenAddress
    )

    // transfer 1 WETH to bancorAdapter
    await USDC.connect(account).transfer(BeethovenxAdapter.address, ethers.utils.parseUnits("100", tokenConfig.tokens.USDC.decimals));

    console.log("before USDC Balance: " + await USDC.balanceOf(BeethovenxAdapter.address));
    console.log("before DAI Balance: " + await DAI.balanceOf(account.address));

    // WETH to LPAL token pool vault
    rxResult = await BeethovenxAdapter.sellBase(
      account.address,                                // receive token address
      VaultAddress,                                  // balancer v2 vault address
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes32"],
        [
          USDC.address,                               // from token address 
          DAI.address,                               // to token address
          poolID  // pool id
        ]
      )
    );
    // console.log(rxResult);

    console.log("after USDC Balance: " + await USDC.balanceOf(BeethovenxAdapter.address));
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
}


async function main() {
    BeethovenxAdapter = await deployContract()
    console.log("====== checkWeightPool =====")
    await checkStablePool(BeethovenxAdapter)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
    // Compare TX
    // https://arbiscan.io/tx/0xe7d7e87b51b752d2b77d430ef52f75437282afc52b8f7bf7d807a7b46411e0c6
    // Network arb
    const tokenConfig = getConfig("arbitrum");
    await setForkNetWorkAndBlockNumber('arbitrum', 107990910);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    USDC_e = await ethers.getContractAt(
      "MockERC20",
      "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
    )

    nextUSDC = await ethers.getContractAt(
      "MockERC20",
      "0x8c556cF37faa0eeDAC7aE665f1Bb0FbD4b2eae36"
    )

    NexttokenAdapter = await ethers.getContractFactory("NexttokenAdapter");
    NexttokenAdapter = await NexttokenAdapter.deploy();
    await NexttokenAdapter.deployed();
    
    await nextUSDC.connect(account).transfer(NexttokenAdapter.address, ethers.utils.parseUnits("0.019996", 6));

    const poolAddr = "0xEE9deC2712cCE65174B561151701Bf54b99C24C8";

    console.log("before nextUSDC Balance: " + await nextUSDC.balanceOf(account.address));
    console.log("before USDC.e Balance: " + await USDC_e.balanceOf(account.address));
    const amount = ethers.utils.parseUnits("0.019996", 6);

    const moreInfo = ethers.utils.solidityPack(["bytes32", "address", "address"],
    [   
        "0x6d9af4a33ed4034765652ab0f44205952bc6d92198d3ef78fe3fb2b078d0941c", 
        "0x8c556cF37faa0eeDAC7aE665f1Bb0FbD4b2eae36", 
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
    ]);
  
    console.log(moreInfo);
    // nextUSDC to USDC.e token pool
    rxResult = await NexttokenAdapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // nextUSDC-USDCe Pool
        moreInfo,
    );

    let gasCost = await getTransactionCost(rxResult);
    console.log("gasCost: "+gasCost);

    console.log(rxResult);
    console.log("after nextUSDC Balance: " + await nextUSDC.balanceOf(account.address));
    console.log("after USDC.e Balance: " + await USDC_e.balanceOf(account.address));
}

const getTransactionCost = async (txResult) => {
  const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
  return ethers.BigNumber.from(cumulativeGasUsed);
};

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

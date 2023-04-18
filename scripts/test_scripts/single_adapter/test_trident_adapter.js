const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");


async function execute() {
    // Compare TX
    // https://optimistic.etherscan.io/tx/0x3966b0abd2108feb56eacb4d24c2465c747c926548c8cc29ca4312d0c9f30923
    // https://polygonscan.com/tx/0x8d27da048f91d6f5faa5f69b2af87773aa6150d874f87fc430fd9aee8e3ba4d3
    // https://bscscan.com/tx/0x33ddb8688d2a8f58e52b5d8407fd4e0efb7abbd96e24111f64e8396a73e092cb
    // https://arbiscan.io/tx/0xd2a563b168d35aedfa5116109d9eeeff39fb45c484c21706dd6d62f24dd334af

    // Network optimism
    await setForkNetWorkAndBlockNumber("op", 89383283);
    // Network polygon
    //await setForkNetWorkAndBlockNumber("polygon", 41479574);
    // Network bsc
    //await setForkNetWorkAndBlockNumber("bsc", 27315966);
    // Network arb
    //await setForkNetWorkAndBlockNumber("arbitrum", 79996063);

    console.log("===== start =====");

    const tokenConfig = getConfig("op");
    //const tokenConfig = getConfig("polygon");
    //const tokenConfig = getConfig("bsc");
    //const tokenConfig = getConfig("arbitrum");
    
    const accountAddress  = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    const poolAddress = "0x7086622E6Db990385B102D79CB1218947fb549a9"; 
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    //op：WETH-USDC 0x7086622E6Db990385B102D79CB1218947fb549a9
    //polyon ：USDC-USDT 0x231BA46173b75E4D7cEa6DCE095A6c1c3E876270
    //bsc：BNB-USDT 0x2f56932cb53d8E292644Da1a62Ed58242B80510e
    //arbitrum：USDT-USDC 0x79bf7147eBCd0d55e83Cb42ed3Ba1bB2Bb23eF20

    // Quote Token
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WETH.baseTokenAddress 
    );
    // Quote = await ethers.getContractAt(
    //   "MockERC20",
    //   tokenConfig.tokens.USDT.baseTokenAddress 
    // );
    // Quote = await ethers.getContractAt(
    //   "MockERC20",
    //   tokenConfig.tokens.WBNB.baseTokenAddress 
    // );    


    // Base Token
    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.USDC.baseTokenAddress 
    );
    // Base = await ethers.getContractAt(
    //   "MockERC20",
    //   tokenConfig.tokens.USDT.baseTokenAddress 
    // );  



    console.log("===== tridentAdapter =====");
    TridentAdapter = await ethers.getContractFactory("TridentAdapter");
    tridentAdapter = await TridentAdapter.deploy("0xc35DADB65012eC5796536bD9864eD8773aBc74C4");
    await tridentAdapter.deployed();
    //op bentobox address 0xc35DADB65012eC5796536bD9864eD8773aBc74C4
    //polygon bentobox address 0x0319000133d3AdA02600f0875d2cf03D442C3367
    //bsc bentobox address 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966
    //arbitrum：0x74c764D41B77DBbb4fe771daB1939B00b146894A


    // check user token
    QuoteBalance = await Quote.balanceOf(accountAddress);
    console.log("User Quote beforeBalance: ", QuoteBalance.toString());
    BaseBalance = await Base.balanceOf(accountAddress);
    console.log("User Base beforeBalance: ", BaseBalance.toString());

    console.log("\n================== SellQuote ==================");
    // transfer quote token to vault

    //op 0.0005 WETH ——> USDC
    testAmount = ethers.utils.parseUnits("0.0005", tokenConfig.tokens.WETH.decimals); 
    //polygon 1 USDT ——> USDC
    //testAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);
    //bsc 0.005 BNB ——> USDT
    //testAmount = ethers.utils.parseUnits("0.005", tokenConfig.tokens.WBNB.decimals);
    //arbitrum 1 USDT ——> USDC
    //testAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.USDT.decimals);
    await Quote.connect(account).transfer(tridentAdapter.address , testAmount);
    
    AdapterQuoteBalance = await Quote.balanceOf(tridentAdapter.address);
    console.log("Adapter Quote beforeBalance: ", AdapterQuoteBalance.toString());
    AdapterBaseBalance = await Base.balanceOf(tridentAdapter.address);
    console.log("Adapter Base beforeBalance: ", AdapterBaseBalance.toString());

    // swap
    rxResult = await tridentAdapter.sellQuote(
      tridentAdapter.address,
      poolAddress,
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [Quote.address, tridentAdapter.address, true]
      )
    );

    // check adapter token
    AdapterQuoteBalance = await Quote.balanceOf(tridentAdapter.address);
    console.log("Adapter Quote afterBalance: ", AdapterQuoteBalance.toString());
    AdapterBaseBalance = await Base.balanceOf(tridentAdapter.address);
    console.log("Adapter Base afterBalance: ", AdapterBaseBalance.toString());
    //console.log(rxResult);


    console.log("\n================== SellBase ==================");

    // swap
    rxResult = await tridentAdapter.sellBase(
      tridentAdapter.address,
      poolAddress,
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [Base.address, tridentAdapter.address, true]
      )
    );

    AdapterQuoteBalance = await Quote.balanceOf(tridentAdapter.address);
    console.log("Adapter Quote afterBalance: ", AdapterQuoteBalance.toString());
    AdapterBaseBalance = await Base.balanceOf(tridentAdapter.address);
    console.log("Adapter Base afterBalance: ", AdapterBaseBalance.toString());
}

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

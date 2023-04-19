const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

//this script is for spiritswapv2（ftm）、cone（bsc）、Dystopia（poly）、Velodrome（op）、Rames Exchanges（arb）、solidlizard（arb）
async function execute() {
    // Compare TX：spiritswap v2
    // https://ftmscan.com/tx/0x8c4527a5fa23e11bdc6440b3e8d958cf87d71a41654255c147b272bc75d1d624
    // In actual transactions, the router will deduct additional handling fees, so the actual transaction balance will be slightly lower
    // swapper will get 193309440/1e18 dai

    // Compare TX：cone
    // https://bscscan.com/tx/0xd1516097493ff8852fa2babe2a1c3f713d154f39d4496c21591f5edf0a3e9a41
    // Compare TX：Dystopia
    // https://polygonscan.com/tx/0xeb4f64e489a71f749b95111f30fdedc2c279224808ca9e238dad3943f5b763fb
    // Compare TX：Velodrome
    // https://optimistic.etherscan.io/tx/0xd0f9c1e2ef8a0fbb48f70ce8c2dfd3dd37dc0ab291e303291282a426b5723d67
    // Compare TX：Rames Exchanges
    // https://arbiscan.io/tx/0x0c1d86cfa6dc1136f9a837179b1ec33800b81c3ce03e13ba74d90262998992a3
    // Compare TX：solidlizard
    // https://arbiscan.io/tx/0xd62e9495b7754895d7bf4e4753110c466eab72acb5c3c52b142bb768b2a1dbfc

    // Network Fantom
    await setForkNetWorkAndBlockNumber('fantom',59053927);
    // Network bsc
    // await setForkNetWorkAndBlockNumber('bsc',27449190);
    // Network polygon
    // await setForkNetWorkAndBlockNumber('polygon',41663535);
    // Network optimism
    // await setForkNetWorkAndBlockNumber('op',91810906);
    // Network arbitrum (Rames Exchanges test)
    // await setForkNetWorkAndBlockNumber('arbitrum',81682360);
    // Network arbitrum (solidlizard)
    // await setForkNetWorkAndBlockNumber('arbitrum',81683387);

    const tokenConfig = getConfig("ftm");
    // const tokenConfig = getConfig("bsc");
    // const tokenConfig = getConfig("polygon");
    // const tokenConfig = getConfig("op");
    // const tokenConfig = getConfig("arbitrum");
     

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    Base = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WFTM.baseTokenAddress
      //tokenConfig.tokens.USDT.baseTokenAddress
    )
    Quote = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.DAI.baseTokenAddress
      //tokenConfig.tokens.USDC.baseTokenAddress
    )

    SolidlyseriesAdapter = await ethers.getContractFactory("SolidlyseriesAdapter");
    solidlyseriesAdapter = await SolidlyseriesAdapter.deploy();
    await solidlyseriesAdapter.deployed();

    const poolAddr = "0x1c8dd14e77C20eB712Dc30bBf687a282CFf904a2";//spiritswapv2（ftm）WFTM-DAI 1WFTM
    //const poolAddr = "0x68ddA7c12f792E17C747A627d41153c103310D74";//cone（bsc）USDT-USDC 1USDT
    //const poolAddr = "0x4570da74232c1A784E77c2a260F85cdDA8e7d47B";//Dystopia（poly）USDC-USDT 1USDT so selling usdt need to use sellquote
    //const poolAddr = "0x7cabA4D27098bdaabB545e21CA5d865519492a25";//Velodrome（op）USDC-USDT 1USDT so selling usdt need to use sellquote
    //const poolAddr = "0xe25c248Ee2D3D5B428F1388659964446b4d78599";//Rames Exchanges（arb）USDT-USDC 1USDT
    //const poolAddr = "0xd7921c1d058FBac04dbf242f7c70Ce5F316E387a";//solidlizard（arb）USDT-USDC 1USDT

    console.log("before Base Balance: " + await Base.balanceOf(account.address));
    console.log("before Quote Balance: " + await Quote.balanceOf(account.address));

    // transfer 1 WFTM to poolAddr
    await Base.connect(account).transfer(poolAddr, ethers.utils.parseEther('1'));
    // transfer 1 USDT to poolAddr
    //await Base.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDT.decimals));

    // sell base token 
    rxResult = await solidlyseriesAdapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        "0x"
    );

    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));

    // transfer 1 DAI to poolAddr
    await Quote.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.DAI.decimals));
    // transfer 1 USDC to poolAddr
    //await Quote.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.USDC.decimals));

    // sell quote token
    rxResult = await solidlyseriesAdapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // Pool
        "0x"
    );
    

    console.log("after Base Balance: " + await Base.balanceOf(account.address));
    console.log("after Quote Balance: " + await Quote.balanceOf(account.address));
}

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

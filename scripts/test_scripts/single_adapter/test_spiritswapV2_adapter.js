const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {
    // Compare TX
    // https://ftmscan.com/tx/0x8c4527a5fa23e11bdc6440b3e8d958cf87d71a41654255c147b272bc75d1d624
    // In actual transactions, the router will deduct additional handling fees, so the actual transaction balance will be slightly lower
    // swapper will get 193309440/1e18 dai

    // Network Fantom
    await setForkNetWorkAndBlockNumber('fantom',59053927);

    const tokenConfig = getConfig("ftm");

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WFTM = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.WFTM.baseTokenAddress
    )
    DAI = await ethers.getContractAt(
      "MockERC20",
      tokenConfig.tokens.DAI.baseTokenAddress
    )

    SpiritswapV2Adapter = await ethers.getContractFactory("SpiritswapV2Adapter");
    spiritswapV2Adapter = await SpiritswapV2Adapter.deploy();
    await spiritswapV2Adapter.deployed();

    const poolAddr = "0x1c8dd14e77C20eB712Dc30bBf687a282CFf904a2";

    console.log("before WFTM Balance: " + await WFTM.balanceOf(account.address));
    console.log("before DAI Balance: " + await DAI.balanceOf(account.address));

    // transfer 1 WFTM to poolAddr
    
    await WFTM.connect(account).transfer(poolAddr, ethers.utils.parseEther('1'));

    // WFTM to DAI token pool
    rxResult = await spiritswapV2Adapter.sellBase(
        account.address,                                // receive token address
        poolAddr,                                       // WFTM-DAI Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after WFTM Balance: " + await WFTM.balanceOf(account.address));
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));

    // transfer 1 DAI to poolAddr
    await DAI.connect(account).transfer(poolAddr, ethers.utils.parseUnits('1',tokenConfig.tokens.DAI.decimals));

    // DAI to WFTM token pool
    rxResult = await spiritswapV2Adapter.sellQuote(
        account.address,                                // receive token address
        poolAddr,                                       // WFTM-DAI Pool
        "0x"
    );
    // console.log(rxResult);

    console.log("after WFTM Balance: " + await WFTM.balanceOf(account.address));
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
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

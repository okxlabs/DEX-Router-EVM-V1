const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
const tokenConfig = getConfig("bsc")

async function deployContract() {
    NerveFinanceAdapter = await ethers.getContractFactory("NerveFinanceAdapter");
    NerveFinanceAdapter = await NerveFinanceAdapter.deploy();
    await NerveFinanceAdapter.deployed();

    return NerveFinanceAdapter
}

async function BUSDToBSCUSD(NerveFinanceAdapter) {

    bn = await ethers.provider.getBlockNumber();
    console.log("bn: ", bn);

    userAddress = "0xf977814e90da44bfa03b6295a0616a897441acec"
    poolAddress = "0x1B3771a66ee31180906972580adE9b81AFc5fCDc"
    const FOREVER = '2000000000'

    startMockAccount([userAddress])
    signer = await ethers.getSigner(userAddress)
    await setBalance(userAddress, "0x53444835ec580000")

    BUSD = await ethers.getContractAt(
        "MockERC20",
        "0xe9e7cea3dedca5984780bafc599bd69add087d56"
    )

    USDC = await ethers.getContractAt(
        "MockERC20",
        "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"
    )

    await BUSD.connect(signer).transfer(NerveFinanceAdapter.address, ethers.utils.parseUnits('1000', tokenConfig.tokens.BUSD.decimals));

    BUSDbeforeBalance = await BUSD.balanceOf(NerveFinanceAdapter.address);
    USDCbeforeBalance = await USDC.balanceOf(NerveFinanceAdapter.address);

    console.log("BUSD before balance: ", BUSDbeforeBalance.toString());
    console.log("USDC before balance: ", USDCbeforeBalance.toString());

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint8", "uint8", "uint256"],
        [
            BUSD.address,
            USDC.address,
            0,
            2,
            FOREVER
        ]
    )

    rxResult = await NerveFinanceAdapter.sellQuote(
        NerveFinanceAdapter.address,
        poolAddress,
        moreInfo
    );

    // console.log(rxResult);

    BUSDafterBalance = await BUSD.balanceOf(NerveFinanceAdapter.address);
    USDCafterBalance = await USDC.balanceOf(NerveFinanceAdapter.address);

    console.log("BUSD after balance: ", BUSDafterBalance.toString());
    console.log("USDC after balance: ", USDCafterBalance.toString());

}

async function main() {
    await setForkNetWorkAndBlockNumber("bsc", 25420374);
    NerveFinanceAdapter = await deployContract();
    console.log("=====swap BUSD-USDC by NerveFinance=====");
    await BUSDToBSCUSD(NerveFinanceAdapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
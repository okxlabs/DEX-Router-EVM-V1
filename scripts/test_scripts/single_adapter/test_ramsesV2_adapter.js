const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
const tokenConfig = getConfig("arb");

async function deployContract() {
    RamsesV2Adapter = await ethers.getContractFactory("RamsesV2Adapter");
    // factory：0xAA2cd7477c451E703f3B9Ba5663334914763edF8
    RamsesV2Adapter = await RamsesV2Adapter.deploy(tokenConfig.tokens.WETH.baseTokenAddress);
    await RamsesV2Adapter.deployed();
    return RamsesV2Adapter
}

async function USDCswapFRAX(RamsesV2Adapter) {

    bn = await ethers.provider.getBlockNumber();
    console.log("bn: ", bn);

    userAddress = "0x358506b4c5c441873ade429c5a2be777578e2c6f"
    UsdcFrax = "0x6A9D961c9602fB484bA3C47c5F822b66721C9669"
    UsdtUsdce = "0x6059Cf1C818979BCCAc5d1F015E1B322D154592f"
    const FOREVER = '2000000000'

    startMockAccount([userAddress])
    signer = await ethers.getSigner(userAddress)
    // await setBalance(userAddress, "0x53444835ec580000")

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    USDC = await ethers.getContractAt(
        "MockERC20",
        "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"
    )

    USDCe = await ethers.getContractAt(
        "MockERC20",
        "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
    ) 

    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    ) 

    FRAX = await ethers.getContractAt(
        "MockERC20",
        "0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F"
    )

    console.log("===== USDC-FRAX =====");
    await USDC.connect(signer).transfer(RamsesV2Adapter.address, ethers.utils.parseUnits('1', 6));

    console.log("USDC before balance: ", (await USDC.balanceOf(userAddress)).toString());
    console.log("FRAX before balance: ", (await FRAX.balanceOf(userAddress)).toString());

    data = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            USDC.address,
            FRAX.address,
        ]
    )

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            data
        ]
    )

    rxResult = await RamsesV2Adapter.sellBase(
        userAddress,
        UsdcFrax,
        moreInfo
    );

    // console.log(rxResult);

    console.log("USDC after balance of sellQuote: ", (await USDC.balanceOf(userAddress)).toString());
    console.log("FRAX after balance of sellQuote: ", (await FRAX.balanceOf(userAddress)).toString());


    await USDT.connect(signer).transfer(RamsesV2Adapter.address, ethers.utils.parseUnits('2', 6));
   
    console.log("===== USDT-USDCe =====");

    console.log("USDT before balance: ", (await USDT.balanceOf(userAddress)).toString());
    console.log("USDCe before balance: ", (await USDCe.balanceOf(userAddress)).toString());

    data2 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint24"],
        [
            USDT.address,
            USDCe.address,
            100
        ]
    )

    moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            data2
        ]
    )

    rxResult2 = await RamsesV2Adapter.sellBase(
        userAddress,
        UsdtUsdce,
        moreInfo2
    );

    console.log("USDT after balance of sellBase: ", (await USDT.balanceOf(userAddress)).toString());
    console.log("USDCe after balance of sellBase: ", (await USDCe.balanceOf(userAddress)).toString());

}



async function main() {
    // await setForkNetWorkAndBlockNumber("arbitrum", 132168016);
    await setForkNetWorkAndBlockNumber("arbitrum", 130376151);
    RamsesV2Adapter = await deployContract();
    console.log("=====swap by RamsesV2=====");
    await USDCswapFRAX(RamsesV2Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
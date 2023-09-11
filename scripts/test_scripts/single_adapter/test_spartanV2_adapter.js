const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
const tokenConfig = getConfig("bsc")

async function deployContract() {
    SpartanV2Adapter = await ethers.getContractFactory("SpartanV2Adapter");
    SpartanV2Adapter = await SpartanV2Adapter.deploy('0xf73d255d1E2b184cDb7ee0a8A064500eB3f6b352');
    await SpartanV2Adapter.deployed();

    return SpartanV2Adapter
}

async function USTswapSPARTA(SpartanV2Adapter) {

    bn = await ethers.provider.getBlockNumber();
    console.log("bn: ", bn);

    userAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
    const FOREVER = '2000000000'

    startMockAccount([userAddress])
    signer = await ethers.getSigner(userAddress)
    // await setBalance(userAddress, "0x53444835ec580000")

    UST = await ethers.getContractAt(
        "MockERC20",
        "0x23396cF899Ca06c4472205fC903bDB4de249D6fC"
    )

    SPARTA = await ethers.getContractAt(
        "MockERC20",
        "0x3910db0600eA925F63C36DdB1351aB6E2c6eb102"
    )

    WBNB = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WBNB.baseTokenAddress
    )

    await UST.connect(signer).transfer(SpartanV2Adapter.address, ethers.utils.parseUnits('1', 18));

    console.log("UST before balance: ", (await UST.balanceOf(userAddress)).toString());
    console.log("SPARTA before balance: ", (await SPARTA.balanceOf(userAddress)).toString());

    console.log("===== UST-SPARTA =====");

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            UST.address,
            SPARTA.address
        ]
    )

    rxResult = await SpartanV2Adapter.sellQuote(
        userAddress,
        userAddress,
        moreInfo
    );

    // console.log(rxResult);

    console.log("UST after balance of sellQuote: ", (await UST.balanceOf(userAddress)).toString());
    console.log("SPARTA after balance of sellQuote: ", (await SPARTA.balanceOf(userAddress)).toString());


    await SPARTA.connect(signer).transfer(SpartanV2Adapter.address, ethers.utils.parseUnits('1', 18));
   
    console.log("===== SPARTA-UST =====");

    moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            SPARTA.address,
            UST.address
        ]
    )

    rxResult2 = await SpartanV2Adapter.sellBase(
        userAddress,
        userAddress,
        moreInfo2
    );

    console.log("UST after balance of sellBase: ", (await UST.balanceOf(userAddress)).toString());
    console.log("SPARTA after balance of sellBase: ", (await SPARTA.balanceOf(userAddress)).toString());


    // console.log("===== swap WBNB-UST =====");
    
    // WBNB = await ethers.getContractAt(
    //     "MockERC20",
    //     tokenConfig.tokens.WBNB.baseTokenAddress
    // )


    // await WBNB.connect(signer).transfer(SpartanV2Adapter.address, ethers.utils.parseUnits('0.001', 18));

    // console.log("WBNB before balance: ", (await WBNB.balanceOf(userAddress)).toString());
    // console.log("UST before balance: ", (await UST.balanceOf(userAddress)).toString());

    // moreInfo3 = ethers.utils.defaultAbiCoder.encode(
    //     ["address", "address"],
    //     [
    //         WBNB.address,
    //         UST.address
    //     ]
    // )

    // rxResult3 = await SpartanV2Adapter.sellQuote(
    //     userAddress,
    //     userAddress,
    //     moreInfo3
    // );

    // // console.log(rxResult);

    // console.log("WBNB after balance of sellQuote: ", (await WBNB.balanceOf(userAddress)).toString());
    // console.log("UST after balance of sellQuote: ", (await UST.balanceOf(userAddress)).toString());


}



async function main() {
    await setForkNetWorkAndBlockNumber("bsc", 31153352);
    SpartanV2Adapter = await deployContract();
    console.log("=====swap UST-SPARTA by Spartan=====");
    await USTswapSPARTA(SpartanV2Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
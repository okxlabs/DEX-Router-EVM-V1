const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, setBalance } = require("../../tools/chain");
const tokenConfig = getConfig("bsc");

async function deployContract() {
    DODOV3Adapter = await ethers.getContractFactory("DODOV3Adapter");
    DODOV3Adapter = await DODOV3Adapter.deploy();
    await DODOV3Adapter.deployed();
    return DODOV3Adapter
}

async function BSCUSD_WETH(DODOV3Adapter) {

    bn = await ethers.provider.getBlockNumber();
    console.log("bn: ", bn);

    userAddress = "0x358506b4c5c441873ade429c5a2be777578e2c6f"
    pool = "0x7979Dd3C3Ac7446F0a05D0BB700a3dF48D36b4cB"
    const FOREVER = '2000000000'

    startMockAccount([userAddress])
    signer = await ethers.getSigner(userAddress)
    // await setBalance(userAddress, "0x53444835ec580000")

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    BSCUSD = await ethers.getContractAt(
        "MockERC20",
        "0x55d398326f99059fF775485246999027B3197955"
    )

    console.log("===== BSCUSD-WETH =====");
    await BSCUSD.connect(signer).transfer(DODOV3Adapter.address, ethers.utils.parseUnits('1', 18));
    // await WETH.connect(signer).transfer(DODOV3Adapter.address, ethers.utils.parseUnits('0.001', 18));
    console.log("BSCUSD before balance: ", (await BSCUSD.balanceOf(userAddress)).toString());
    console.log("WETH before balance: ", (await WETH.balanceOf(userAddress)).toString());

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            BSCUSD.address,
            WETH.address
        ]
    )

    rxResult = await DODOV3Adapter.sellBase(
        userAddress,
        pool,
        moreInfo
    );

    // console.log(rxResult);

    console.log("BSCUSD after balance of sellQuote: ", (await BSCUSD.balanceOf(userAddress)).toString());
    console.log("WETH after balance of sellQuote: ", (await WETH.balanceOf(userAddress)).toString());

}

async function BTCB_WBNB(DODOV3Adapter) {

    bn = await ethers.provider.getBlockNumber();
    console.log("bn: ", bn);

    userAddress = "0xFdbC996c933bF282261e8a93B2305fbf90D155a7"
    pool = "0x7979Dd3C3Ac7446F0a05D0BB700a3dF48D36b4cB"
    const FOREVER = '2000000000'

    startMockAccount([userAddress])
    signer = await ethers.getSigner(userAddress)
    // await setBalance(userAddress, "0x53444835ec580000")

    BTCB = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BTCB.baseTokenAddress
    )

    WBNB = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WBNB.baseTokenAddress
    )

    console.log("===== BTCB-WBNB =====");
    await BTCB.connect(signer).transfer(DODOV3Adapter.address, ethers.utils.parseUnits('0.023795052156461040', 18));

    console.log("BTCB before balance: ", (await BTCB.balanceOf(userAddress)).toString());
    console.log("WBNB before balance: ", (await WBNB.balanceOf(userAddress)).toString());

    moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            BTCB.address,
            WBNB.address
        ]
    )

    rxResult = await DODOV3Adapter.sellBase(
        userAddress,
        pool,
        moreInfo
    );

    // console.log(rxResult);

    console.log("BTCB after balance of sellQuote: ", (await BTCB.balanceOf(userAddress)).toString());
    console.log("WBNB after balance of sellQuote: ", (await WBNB.balanceOf(userAddress)).toString());

}

async function main() {
    // await setForkNetWorkAndBlockNumber("bsc", 32102658);
    await setForkNetWorkAndBlockNumber("bsc", 32107460);
    DODOV3Adapter = await deployContract();
    console.log("=====swap by DODOV3=====");
    await BTCB_WBNB(DODOV3Adapter);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
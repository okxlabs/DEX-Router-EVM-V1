const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122
const ETH_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
async function deployContractEth() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

    OneinchV1Adapter = await ethers.getContractFactory("OneinchV1Adapter");
    OneinchV1Adapter = await OneinchV1Adapter.deploy(WETH);
    await OneinchV1Adapter.deployed();
    return OneinchV1Adapter
}

async function deployContractBsc() {
    const WETH = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"

    OneinchV1Adapter = await ethers.getContractFactory("OneinchV1Adapter");
    OneinchV1Adapter = await OneinchV1Adapter.deploy(WETH);
    await OneinchV1Adapter.deployed();
    return OneinchV1Adapter
}

// https://openchain.xyz/trace/ethereum/0x4994924f24dc73d67de6c476c6d6bb4c77d5c701cd16d38ee99ada9290f9c2e4

async function executeERC20ToERC20_eth() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17165485 - 1);

    const OneinchV1Adapter = await deployContractEth();

    const accountSource = "0x9A0C8Ff858d273f57072D714bca7411D717501D7"
    const accountAddr = "0x1000000000000000011000000000000000000000"
    const poolAddr = "0x69AB07348F51c639eF81d7991692f0049b10D522"



    const INCH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.INCH.baseTokenAddress
    );

    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await INCH.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("677202348427858798834")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "before INCH balance: " + (await INCH.balanceOf(account.address))
    );

    await INCH.connect(account).transfer(
        OneinchV1Adapter.address,
        ethers.BigNumber.from("677202348427858798834")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            INCH.address,
            USDC.address
        ]
    );
    await OneinchV1Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "after INCH balance: " + (await INCH.balanceOf(account.address))
    );
}

// https://openchain.xyz/trace/ethereum/0x5dbaf716af99a572b9b5b55e9e42cbc2b8b87ab6dabcebd05810482362ae336c

async function executeERC20ToETH_eth() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17146971 - 1);

    const OneinchV1Adapter = await deployContractEth();

    const accountSource = "0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656"
    const accountAddr = "0x1000000000000000011000000000000000000000"
    const poolAddr = "0x6a11F3E5a01D129e566d783A7b6E8862bFD66CcA"



    const WBTC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WBTC.baseTokenAddress
    );

    const WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await WBTC.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("324052")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "before WBTC balance: " + (await WBTC.balanceOf(account.address))
    );

    await WBTC.connect(account).transfer(
        OneinchV1Adapter.address,
        ethers.BigNumber.from("324052")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            WBTC.address,
            ETH_ADDR
        ]
    );
    await OneinchV1Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "after WBTC balance: " + (await WBTC.balanceOf(account.address))
    );
}


// https://openchain.xyz/trace/ethereum/0x5dbaf716af99a572b9b5b55e9e42cbc2b8b87ab6dabcebd05810482362ae336c

async function executeETHToERC20_eth() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17146971 - 1);

    const OneinchV1Adapter = await deployContractEth();

    const accountSource = "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e"
    const accountAddr = "0x1000000000000000011000000000000000000000"
    const poolAddr = "0x6a11F3E5a01D129e566d783A7b6E8862bFD66CcA"



    const WBTC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WBTC.baseTokenAddress
    );

    const WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await WETH.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("49562500000000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "before WBTC balance: " + (await WBTC.balanceOf(account.address))
    );

    await WETH.connect(account).transfer(
        OneinchV1Adapter.address,
        ethers.BigNumber.from("49562500000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            ETH_ADDR,
            WBTC.address
        ]
    );
    await OneinchV1Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "after WBTC balance: " + (await WBTC.balanceOf(account.address))
    );
}




async function main() {

    console.log("==== checking ERC20 to ERC20 ====== ")
    await executeERC20ToERC20_eth();
    console.log("==== checking ETH to ERC20 ====== ")
    await executeETHToERC20_eth();
    console.log("==== checking ERC20 to ETH ====== ")
    await executeERC20ToETH_eth();





}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

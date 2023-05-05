const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {

    MstableAdapter = await ethers.getContractFactory("MstableAdapter");
    MstableAdapter = await MstableAdapter.deploy();
    await MstableAdapter.deployed();
    return MstableAdapter
}



// https://etherscan.io/tx/0x5f822b50ab97a3b4c3df40d6fa38967d45d2740f14493b86d603585897ff1045

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 16544568 - 1);

    const MstableAdapter = await deployContract();

    const accountSource = "0x0b20ba9cb451b3f5bc528762370884ed75e09c1b"
    const accountAddr = "0x1000000000000000000000000000000010000000"
    const poolAddr = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await USDC.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("45000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );

    await USDC.connect(account).transfer(
        MstableAdapter.address,
        ethers.BigNumber.from("45000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            USDC.address,
            USDT.address
        ]
    );
    await MstableAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
}

// https://openchain.xyz/trace/ethereum/0x3a99152421ded9ce7871ab753b235950d0253e04e12abd572a6bfdaa33e8a712
async function executeERC20ToMUSD() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 16653983 - 1);

    const MstableAdapter = await deployContract();

    const accountSource = "0x1C832dD1B92C9385Dd0bdc50a7FB29b433dc495D"
    const accountAddr = "0x1000000000000000000000000000000010000000"
    const poolAddr = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5"


    const DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    );

    const mUSD = await ethers.getContractAt(
        "MockERC20",
        poolAddr
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await DAI.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("50794890221890360922")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before mUSD balance: " + (await mUSD.balanceOf(account.address))
    );
    console.log(
        "before DAI balance: " + (await DAI.balanceOf(account.address))
    );

    await DAI.connect(account).transfer(
        MstableAdapter.address,
        ethers.BigNumber.from("50794890221890360922")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            DAI.address,
            mUSD.address
        ]
    );
    await MstableAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after mUSD balance: " + (await mUSD.balanceOf(account.address))
    );
    console.log(
        "after DAI balance: " + (await DAI.balanceOf(account.address))
    );
}

// https://openchain.xyz/trace/ethereum/0x65dea8191b8ecce29d9bbeb31a7d78841d8cdc351f62a4a849f2134ce9485b37
async function executeMUSDToERC20() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 16723877 - 1);

    const MstableAdapter = await deployContract();

    const accountSource = "0xe18B7E20c0b9A8FA16C20911B706Be8DC69d3485"
    const accountAddr = "0x1000000000000000000000000000000010000000"
    const poolAddr = "0xe2f2a5c287993345a840db3b0845fbc70f5935a5"


    const mUSD = await ethers.getContractAt(
        "MockERC20",
        poolAddr
    );

    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await mUSD.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("3000000000000000000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "before mUSD balance: " + (await mUSD.balanceOf(account.address))
    );

    await mUSD.connect(account).transfer(
        MstableAdapter.address,
        ethers.BigNumber.from("3000000000000000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            mUSD.address,
            USDC.address
        ]
    );
    await MstableAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "after mUSD balance: " + (await mUSD.balanceOf(account.address))
    );
}

// https://openchain.xyz/trace/ethereum/0x05167e677a779060a5eb65bf7cadd75a35166996feed23a6c31d5ef9823f55e5

async function executeFeeder() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 16292442 - 1);

    const MstableAdapter = await deployContract();

    const accountSource = "0xeb1520Bb8829386d5AA2C3Aa99929B6aDfAEb175"
    const accountAddr = "0x1000000000000000000000000000000010000000"
    const poolAddr = "0x4eaa01974B6594C0Ee62fFd7FEE56CF11E6af936"

    const alUSDAddr = "0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9";


    const alUSD = await ethers.getContractAt(
        "MockERC20",
        alUSDAddr
    );

    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await alUSD.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("552618452371711657475")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "before alUSD balance: " + (await alUSD.balanceOf(account.address))
    );

    await alUSD.connect(account).transfer(
        MstableAdapter.address,
        ethers.BigNumber.from("552618452371711657475")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            alUSD.address,
            USDC.address
        ]
    );
    await MstableAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "after alUSD balance: " + (await alUSD.balanceOf(account.address))
    );
}

async function main() {

    console.log("==== checking ERC20 to ERC20 ====== ")
    await executeERC20ToERC20();
    console.log("==== checking mUSD to ERC20 ====== ")
    await executeMUSDToERC20();
    console.log("==== checking ERC20 to mUSD ====== ")
    await executeERC20ToMUSD();

    console.log("==== checking Feeder ====== ")
    await executeFeeder();




}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
